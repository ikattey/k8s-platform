output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.cluster.name
}

output "cluster_location" {
  description = "GKE cluster location"
  value       = google_container_cluster.cluster.location
}

output "cluster_endpoint" {
  description = "GKE API endpoint"
  value       = google_container_cluster.cluster.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64 encoded cluster CA certificate"
  value       = google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "network_name" {
  description = "VPC network name"
  value       = google_compute_network.vpc.name
}

output "network_self_link" {
  description = "VPC network self link"
  value       = google_compute_network.vpc.self_link
}

output "subnetwork_name" {
  description = "Subnetwork name"
  value       = google_compute_subnetwork.subnet.name
}

output "configure_kubectl" {
  description = "gcloud command to configure kubectl"
  value       = "gcloud container clusters get-credentials ${google_container_cluster.cluster.name} --location ${google_container_cluster.cluster.location} --project ${var.project_id}"
}

output "object_storage_provider" {
  description = "Platform object storage provider"
  value       = var.create_backup_bucket ? "gcs" : null
}

output "object_storage_endpoint" {
  description = "Object storage endpoint used by CNPG's S3-compatible backup client"
  value       = var.create_backup_bucket ? "https://storage.googleapis.com" : ""
}

output "object_storage_region" {
  description = "Object storage region"
  value       = var.region
}

output "object_storage_bucket_names" {
  description = "Logical object storage bucket names"
  value = var.create_backup_bucket ? {
    "loki-chunks"  = google_storage_bucket.backups[0].name
    "loki-ruler"   = google_storage_bucket.backups[0].name
    "cnpg-backups" = google_storage_bucket.backups[0].name
  } : null
}

output "workload_identity_pool" {
  description = "Workload Identity pool"
  value       = "${var.project_id}.svc.id.goog"
}

output "cnpg_backup_access_key_id" {
  description = "Static HMAC access key ID for CNPG backups"
  value       = var.create_backup_bucket ? google_storage_hmac_key.cnpg[0].access_id : null
}

output "cnpg_backup_secret_access_key" {
  description = "Static HMAC secret access key for CNPG backups"
  value       = var.create_backup_bucket ? google_storage_hmac_key.cnpg[0].secret : null
  sensitive   = true
}

output "monitoring_service_account_email" {
  description = "Google service account email for monitoring storage"
  value       = var.create_backup_bucket ? google_service_account.monitoring[0].email : null
}
