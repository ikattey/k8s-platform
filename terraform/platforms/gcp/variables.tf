variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "cluster_name" {
  description = "GKE cluster name"
  type        = string
}

variable "environment" {
  description = "Environment label"
  type        = string
  default     = "production"
}

variable "region" {
  description = "GCP region"
  type        = string
}

variable "location" {
  description = "GKE location (regional or zonal)"
  type        = string
}

variable "subnet_cidr" {
  description = "Primary subnet CIDR"
  type        = string
  default     = "10.10.0.0/20"
}

variable "pods_cidr" {
  description = "GKE pod CIDR"
  type        = string
  default     = "10.20.0.0/16"
}

variable "services_cidr" {
  description = "GKE service CIDR"
  type        = string
  default     = "10.30.0.0/20"
}

variable "node_count" {
  description = "Minimum number of general nodes"
  type        = number
  default     = 3
}

variable "max_node_count" {
  description = "Maximum number of general nodes"
  type        = number
  default     = 6
}

variable "machine_type" {
  description = "Machine type for general nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "disk_size_gb" {
  description = "Boot disk size for general nodes"
  type        = number
  default     = 100
}

variable "spot" {
  description = "Use Spot VMs for the general node pool"
  type        = bool
  default     = false
}

variable "enable_storage_node_pool" {
  description = "Create a dedicated storage node pool"
  type        = bool
  default     = true
}

variable "storage_node_count" {
  description = "Minimum number of storage nodes"
  type        = number
  default     = 1
}

variable "storage_max_node_count" {
  description = "Maximum number of storage nodes"
  type        = number
  default     = 2
}

variable "storage_machine_type" {
  description = "Machine type for storage nodes"
  type        = string
  default     = "n2-standard-2"
}

variable "storage_disk_size_gb" {
  description = "Boot disk size for storage nodes"
  type        = number
  default     = 100
}

variable "storage_spot" {
  description = "Use Spot VMs for storage nodes"
  type        = bool
  default     = false
}

variable "create_backup_bucket" {
  description = "Create a GCS bucket for Loki, CNPG, and Velero"
  type        = bool
  default     = true
}

variable "backup_bucket_name" {
  description = "Existing or desired backup bucket name; leave empty for auto-generated"
  type        = string
  default     = ""
}

variable "backup_retention_days" {
  description = "Object lifecycle retention for the backup bucket"
  type        = number
  default     = 30
}

variable "deletion_protection" {
  description = "Enable cluster deletion protection"
  type        = bool
  default     = true
}

variable "master_authorized_cidr_blocks" {
  description = "CIDR blocks allowed to access the GKE master endpoint. Empty list means unrestricted."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}
