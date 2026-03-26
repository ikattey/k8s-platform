variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "network_self_link" {
  description = "Self link of the VPC network used for private service networking"
  type        = string
}

variable "instance_name" {
  description = "Cloud SQL instance name"
  type        = string
}

variable "database_name" {
  description = "Application database name"
  type        = string
  default     = "app"
}

variable "database_user" {
  description = "Application database user"
  type        = string
  default     = "app"
}

variable "database_version" {
  description = "PostgreSQL major version"
  type        = string
  default     = "POSTGRES_16"
}

variable "tier" {
  description = "Cloud SQL machine tier"
  type        = string
  default     = "db-custom-2-4096"
}

variable "disk_size_gb" {
  description = "Initial disk size in GB"
  type        = number
  default     = 20
}

variable "availability_type" {
  description = "Cloud SQL availability type (ZONAL or REGIONAL)"
  type        = string
  default     = "ZONAL"
}

variable "backup_start_time" {
  description = "Backup window start time in UTC"
  type        = string
  default     = "02:00"
}

variable "deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "environment" {
  description = "Environment tag/label"
  type        = string
  default     = "production"
}
