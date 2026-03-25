output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded CA data"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_provider" {
  description = "OIDC provider URL"
  value       = module.eks.oidc_provider
}

output "cluster_oidc_provider_arn" {
  description = "OIDC provider ARN"
  value       = module.eks.oidc_provider_arn
}

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "node_security_group_id" {
  description = "Worker node security group"
  value       = module.eks.node_security_group_id
}

output "configure_kubectl" {
  description = "aws command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}

output "object_storage_provider" {
  description = "Platform object storage provider"
  value       = var.create_backup_bucket ? "s3" : null
}

output "object_storage_endpoint" {
  description = "Object storage endpoint"
  value       = ""
}

output "object_storage_region" {
  description = "Object storage region"
  value       = var.region
}

output "object_storage_bucket_names" {
  description = "Logical object storage bucket names"
  value = var.create_backup_bucket ? {
    "loki-chunks"  = aws_s3_bucket.backups[0].id
    "loki-ruler"   = aws_s3_bucket.backups[0].id
    "cnpg-backups" = aws_s3_bucket.backups[0].id
  } : null
}

output "cnpg_backup_role_arn" {
  description = "IRSA role for CNPG backups"
  value       = var.create_backup_bucket ? aws_iam_role.cnpg[0].arn : null
}

output "monitoring_storage_role_arn" {
  description = "IRSA role for Loki storage"
  value       = var.create_backup_bucket ? aws_iam_role.monitoring[0].arn : null
}

