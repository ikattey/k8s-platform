variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for regional resources and bucket placement"
  type        = string
  default     = "europe-west1"
}

variable "location" {
  description = "GKE location (regional or zonal)"
  type        = string
  default     = "europe-west1-b"
}

variable "cluster_name" {
  description = "Starter cluster name"
  type        = string
  default     = "gcp-starter"
}

variable "environment" {
  description = "Environment label"
  type        = string
  default     = "production"
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
  description = "Minimum number of general-purpose nodes"
  type        = number
  default     = 3
}

variable "max_node_count" {
  description = "Maximum number of general-purpose nodes"
  type        = number
  default     = 6
}

variable "machine_type" {
  description = "Machine type for the general node pool"
  type        = string
  default     = "e2-standard-4"
}

variable "spot" {
  description = "Use Spot VMs for the general node pool"
  type        = bool
  default     = false
}

variable "disk_size_gb" {
  description = "Boot disk size for general nodes"
  type        = number
  default     = 100
}

variable "enable_storage_node_pool" {
  description = "Create a dedicated storage node pool. Enable when running CNPG or other stateful workloads that need dedicated storage nodes."
  type        = bool
  default     = false
}

variable "storage_node_count" {
  description = "Minimum number of dedicated storage nodes"
  type        = number
  default     = 1
}

variable "storage_max_node_count" {
  description = "Maximum number of dedicated storage nodes"
  type        = number
  default     = 2
}

variable "storage_machine_type" {
  description = "Machine type for the dedicated storage node pool"
  type        = string
  default     = "n2-standard-2"
}

variable "storage_spot" {
  description = "Use Spot VMs for the storage node pool"
  type        = bool
  default     = false
}

variable "storage_disk_size_gb" {
  description = "Boot disk size for the storage node pool"
  type        = number
  default     = 100
}

variable "create_backup_bucket" {
  description = "Create a shared GCS bucket for Loki, CNPG, and Velero"
  type        = bool
  default     = true
}

variable "backup_bucket_name" {
  description = "Optional backup bucket name; leave empty to auto-generate"
  type        = string
  default     = ""
}

variable "backup_retention_days" {
  description = "Retention period for objects in the shared backup bucket"
  type        = number
  default     = 30
}

variable "deletion_protection" {
  description = "Protect the GKE cluster from accidental deletion"
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

variable "database_provider" {
  description = "Database provider: cnpg (default), managed, or external"
  type        = string
  default     = "cnpg"

  validation {
    condition     = contains(["cnpg", "managed", "external"], var.database_provider)
    error_message = "database_provider must be one of: cnpg, managed, external"
  }
}

variable "database_name" {
  description = "Application database name when using Cloud SQL"
  type        = string
  default     = "app"
}

variable "database_username" {
  description = "Application database user when using Cloud SQL"
  type        = string
  default     = "app"
}

variable "cloud_sql_tier" {
  description = "Cloud SQL machine tier when database_provider=managed"
  type        = string
  default     = "db-custom-2-4096"
}

variable "cloud_sql_disk_size_gb" {
  description = "Initial Cloud SQL disk size when database_provider=managed"
  type        = number
  default     = 20
}

variable "cloud_sql_availability_type" {
  description = "Cloud SQL availability type (ZONAL or REGIONAL)"
  type        = string
  default     = "ZONAL"
}
