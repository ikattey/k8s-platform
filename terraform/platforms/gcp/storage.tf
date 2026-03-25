resource "random_id" "bucket_suffix" {
  count       = var.create_backup_bucket ? 1 : 0
  byte_length = 4
}

locals {
  bucket_suffix = var.create_backup_bucket ? random_id.bucket_suffix[0].hex : ""
  bucket_labels = {
    environment = var.environment
    cluster     = var.cluster_name
    managed_by  = "terraform"
  }
}

resource "google_storage_bucket" "backups" {
  count    = var.create_backup_bucket ? 1 : 0
  project  = var.project_id
  name     = var.backup_bucket_name != "" ? var.backup_bucket_name : "${var.cluster_name}-backups-${local.bucket_suffix}"
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

  labels = local.bucket_labels
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

resource "google_storage_bucket_iam_member" "cnpg_bucket_access" {
  count  = var.create_backup_bucket ? 1 : 0
  bucket = google_storage_bucket.backups[0].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.cnpg[0].email}"
}

resource "google_storage_hmac_key" "cnpg" {
  count                 = var.create_backup_bucket ? 1 : 0
  project               = var.project_id
  service_account_email = google_service_account.cnpg[0].email
  state                 = "ACTIVE"
}

resource "google_storage_bucket_iam_member" "monitoring_bucket_access" {
  count  = var.create_backup_bucket ? 1 : 0
  bucket = google_storage_bucket.backups[0].name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.monitoring[0].email}"
}
