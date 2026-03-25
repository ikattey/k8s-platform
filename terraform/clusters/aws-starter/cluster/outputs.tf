output "cluster_name" {
  description = "EKS cluster name"
  value       = module.platform.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.platform.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded cluster CA certificate"
  value       = module.platform.cluster_certificate_authority_data
  sensitive   = true
}

output "configure_kubectl" {
  description = "aws eks command to configure kubectl"
  value       = module.platform.configure_kubectl
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "environment" {
  description = "Environment tag"
  value       = var.environment
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.platform.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.platform.private_subnet_ids
}

output "node_security_group_id" {
  description = "Worker node security group ID"
  value       = module.platform.node_security_group_id
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

output "cnpg_backup_access_key_id" {
  description = "Static access key ID for CNPG backups"
  value       = module.platform.cnpg_backup_access_key_id
}

output "cnpg_backup_secret_access_key" {
  description = "Static secret access key for CNPG backups"
  value       = module.platform.cnpg_backup_secret_access_key
  sensitive   = true
}

output "monitoring_storage_role_arn" {
  description = "IRSA role ARN for Loki object storage"
  value       = module.platform.monitoring_storage_role_arn
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
