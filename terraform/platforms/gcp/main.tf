resource "google_project_service" "required" {
  for_each = toset([
    "container.googleapis.com",
    "compute.googleapis.com",
    "iamcredentials.googleapis.com",
    "storage.googleapis.com"
  ])

  project            = var.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                    = "${var.cluster_name}-vpc"
  auto_create_subnetworks = false

  depends_on = [google_project_service.required]
}

resource "google_compute_subnetwork" "subnet" {
  project                  = var.project_id
  name                     = "${var.cluster_name}-subnet"
  region                   = var.region
  network                  = google_compute_network.vpc.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true
}

resource "google_container_cluster" "cluster" {
  project  = var.project_id
  name     = var.cluster_name
  location = var.location

  remove_default_node_pool = true
  initial_node_count       = 1

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

  deletion_protection = var.deletion_protection

  release_channel {
    channel = "REGULAR"
  }

  ip_allocation_policy {
    cluster_ipv4_cidr_block  = var.pods_cidr
    services_ipv4_cidr_block = var.services_cidr
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  addons_config {
    gce_persistent_disk_csi_driver_config {
      enabled = true
    }
    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  maintenance_policy {
    recurring_window {
      recurrence = "FREQ=WEEKLY;BYDAY=SU"
      start_time = "2026-01-01T02:00:00Z"
      end_time   = "2026-01-01T06:00:00Z"
    }
  }

  depends_on = [google_project_service.required]
}

resource "google_container_node_pool" "general" {
  project  = var.project_id
  name     = "general"
  location = var.location
  cluster  = google_container_cluster.cluster.name

  node_count = var.node_count

  autoscaling {
    min_node_count = var.node_count
    max_node_count = var.max_node_count
  }

  lifecycle {
    ignore_changes = [node_count]
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.machine_type
    spot         = var.spot
    disk_size_gb = var.disk_size_gb
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    labels = {
      environment = var.environment
      role        = "general"
    }
  }
}

resource "google_container_node_pool" "storage" {
  count    = var.enable_storage_node_pool ? 1 : 0
  project  = var.project_id
  name     = "storage"
  location = var.location
  cluster  = google_container_cluster.cluster.name

  node_count = var.storage_node_count

  autoscaling {
    min_node_count = var.storage_node_count
    max_node_count = var.storage_max_node_count
  }

  lifecycle {
    ignore_changes        = [node_count]
    create_before_destroy = true
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.storage_machine_type
    spot         = var.storage_spot
    disk_size_gb = var.storage_disk_size_gb
    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]

    labels = {
      environment    = var.environment
      role           = "storage"
      "server-usage" = "storage"
    }

    taint {
      key    = "storage"
      value  = "true"
      effect = "NO_SCHEDULE"
    }
  }
}
