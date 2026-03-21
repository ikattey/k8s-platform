resource "random_id" "bucket_suffix" {
  count       = var.create_backup_bucket && var.backup_bucket_name == "" ? 1 : 0
  byte_length = 4
}

resource "google_storage_bucket" "backups" {
  count    = var.create_backup_bucket ? 1 : 0
  project  = var.project_id
  name     = var.backup_bucket_name != "" ? var.backup_bucket_name : "${var.cluster_name}-backups-${random_id.bucket_suffix[0].hex}"
  location = var.region

  storage_class               = "STANDARD"
  force_destroy               = !var.deletion_protection
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = var.backup_retention_days
    }
  }

  labels = {
    environment = var.environment
    cluster     = var.cluster_name
    managed_by  = "terraform"
    purpose     = "platform-backups"
  }
}

resource "google_service_account" "cnpg" {
  count        = var.create_backup_bucket ? 1 : 0
  project      = var.project_id
  account_id   = "${substr(replace(var.cluster_name, "/[^a-z0-9-]/", "-"), 0, 20)}-cnpg"
  display_name = "CNPG backups for ${var.cluster_name}"
}

resource "google_service_account" "monitoring" {
  count        = var.create_backup_bucket ? 1 : 0
  project      = var.project_id
  account_id   = "${substr(replace(var.cluster_name, "/[^a-z0-9-]/", "-"), 0, 20)}-loki"
  display_name = "Monitoring storage for ${var.cluster_name}"
}

resource "google_service_account" "velero" {
  count        = var.create_backup_bucket ? 1 : 0
  project      = var.project_id
  account_id   = "${substr(replace(var.cluster_name, "/[^a-z0-9-]/", "-"), 0, 20)}-velero"
  display_name = "Velero for ${var.cluster_name}"
}

resource "google_storage_bucket_iam_member" "cnpg_bucket_access" {
  count  = var.create_backup_bucket ? 1 : 0
  bucket = google_storage_bucket.backups[0].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cnpg[0].email}"
}

resource "google_storage_bucket_iam_member" "monitoring_bucket_access" {
  count  = var.create_backup_bucket ? 1 : 0
  bucket = google_storage_bucket.backups[0].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.monitoring[0].email}"
}

resource "google_storage_bucket_iam_member" "velero_bucket_access" {
  count  = var.create_backup_bucket ? 1 : 0
  bucket = google_storage_bucket.backups[0].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.velero[0].email}"
}
