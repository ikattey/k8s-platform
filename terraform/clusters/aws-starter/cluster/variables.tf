variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "cluster_name" {
  description = "Starter cluster name"
  type        = string
  default     = "aws-starter"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.40.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones used by the cluster"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b", "eu-west-1c"]
}

variable "single_nat_gateway" {
  description = "Use a single NAT gateway to reduce starter cost"
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.31"
}

variable "cluster_endpoint_public_access" {
  description = "Expose the EKS API publicly"
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Expose the EKS API privately"
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDR blocks allowed to reach the public EKS endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "general_min_size" {
  description = "Minimum number of general-purpose nodes"
  type        = number
  default     = 2
}

variable "general_max_size" {
  description = "Maximum number of general-purpose nodes"
  type        = number
  default     = 6
}

variable "general_desired_size" {
  description = "Desired number of general-purpose nodes"
  type        = number
  default     = 3
}

variable "general_instance_types" {
  description = "Instance types for the general-purpose node group"
  type        = list(string)
  default     = ["m5.large", "m6i.large", "m6a.large"]
}

variable "storage_enabled" {
  description = "Create a dedicated storage node group"
  type        = bool
  default     = true
}

variable "storage_min_size" {
  description = "Minimum number of storage nodes"
  type        = number
  default     = 1
}

variable "storage_max_size" {
  description = "Maximum number of storage nodes"
  type        = number
  default     = 2
}

variable "storage_desired_size" {
  description = "Desired number of storage nodes"
  type        = number
  default     = 1
}

variable "storage_instance_types" {
  description = "Instance types for the storage node group"
  type        = list(string)
  default     = ["m5.large"]
}

variable "create_backup_bucket" {
  description = "Create a shared S3 bucket for Loki, CNPG, and Velero"
  type        = bool
  default     = true
}

variable "backup_bucket_name" {
  description = "Optional backup bucket name; leave empty to auto-generate"
  type        = string
  default     = ""
}

variable "backup_retention_days" {
  description = "Retention policy for objects in the shared backup bucket"
  type        = number
  default     = 30
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
  description = "Application database name when database_provider=managed"
  type        = string
  default     = "app"
}

variable "database_username" {
  description = "Application database user when database_provider=managed"
  type        = string
  default     = "app"
}

variable "rds_instance_class" {
  description = "RDS instance class when database_provider=managed"
  type        = string
  default     = "db.t4g.small"
}

variable "rds_engine_version" {
  description = "Managed PostgreSQL engine version"
  type        = string
  default     = "16"
}

variable "rds_allocated_storage" {
  description = "Initial RDS storage in GiB"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Maximum autoscaled RDS storage in GiB"
  type        = number
  default     = 100
}

variable "rds_multi_az" {
  description = "Enable Multi-AZ for the starter RDS instance"
  type        = bool
  default     = false
}

variable "deletion_protection" {
  description = "Protect RDS from accidental deletion"
  type        = bool
  default     = true
}
