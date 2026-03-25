output "cluster_name" {
  description = "GKE cluster name"
  value       = module.platform.cluster_name
}

output "cluster_endpoint" {
  description = "GKE cluster API endpoint"
  value       = module.platform.cluster_endpoint
}

output "cluster_ca_certificate" {
  description = "Base64 encoded cluster CA certificate"
  value       = module.platform.cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "GKE location"
  value       = module.platform.cluster_location
}

output "configure_kubectl" {
  description = "gcloud command to configure kubectl"
  value       = module.platform.configure_kubectl
}

output "project_id" {
  description = "GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "GCP region"
  value       = var.region
}

output "location" {
  description = "GKE location"
  value       = var.location
}

output "environment" {
  description = "Environment label"
  value       = var.environment
}

output "network_name" {
  description = "VPC network name"
  value       = module.platform.network_name
}

output "network_self_link" {
  description = "VPC network self link"
  value       = module.platform.network_self_link
}

output "subnetwork_name" {
  description = "Subnetwork name"
  value       = module.platform.subnetwork_name
}

output "object_storage_provider" {
  description = "Object storage provider"
  value       = module.platform.object_storage_provider
}

output "object_storage_endpoint" {
  description = "Object storage endpoint"
  value       = module.platform.object_storage_endpoint
}

output "object_storage_region" {
  description = "Object storage region"
  value       = module.platform.object_storage_region
}

output "object_storage_bucket_names" {
  description = "Map of logical object storage buckets"
  value       = module.platform.object_storage_bucket_names
}

output "workload_identity_pool" {
  description = "Workload Identity pool"
  value       = module.platform.workload_identity_pool
}

output "cnpg_backup_access_key_id" {
  description = "Static HMAC access key ID for CNPG backups"
  value       = module.platform.cnpg_backup_access_key_id
}

output "cnpg_backup_secret_access_key" {
  description = "Static HMAC secret access key for CNPG backups"
  value       = module.platform.cnpg_backup_secret_access_key
  sensitive   = true
}

output "monitoring_service_account_email" {
  description = "Google service account email used for Loki object storage"
  value       = module.platform.monitoring_service_account_email
}

output "database_host" {
  description = "Managed database host when database_provider=managed"
  value       = var.database_provider == "managed" ? module.database[0].host : null
}

output "database_port" {
  description = "Managed database port when database_provider=managed"
  value       = var.database_provider == "managed" ? module.database[0].port : null
}

output "database_name" {
  description = "Managed database name when database_provider=managed"
  value       = var.database_provider == "managed" ? module.database[0].database_name : null
}

output "database_username" {
  description = "Managed database username when database_provider=managed"
  value       = var.database_provider == "managed" ? module.database[0].username : null
}

output "database_password" {
  description = "Managed database password when database_provider=managed"
  value       = var.database_provider == "managed" ? module.database[0].password : null
  sensitive   = true
}
