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
  description = "Explicit availability zones. If empty, az_count zones are selected automatically."
  type        = list(string)
  default     = []
}

variable "az_count" {
  description = "Number of availability zones to use when availability_zones is empty"
  type        = number
  default     = 2
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

variable "enable_cloudwatch_logging" {
  description = "Send EKS control plane logs to CloudWatch. Off by default (use Loki). Enable for audit compliance."
  type        = bool
  default     = false
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
  default     = ["m5.large", "m5a.large", "m6i.large", "m6a.large"]
}

variable "enable_storage_node_pool" {
  description = "Create a dedicated storage node group. Enable when running CNPG or other stateful workloads that need dedicated storage nodes."
  type        = bool
  default     = false
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

variable "enable_spot_instances" {
  description = "Use Spot instances for the general node pool. Enable for cost savings. Not recommended for platform-layer nodes."
  type        = bool
  default     = false
}

variable "create_backup_bucket" {
  description = "Create a shared S3 bucket for Loki and CNPG"
  type        = bool
  default     = true
}

variable "force_destroy_backup_bucket" {
  description = "Allow Terraform to destroy the backup bucket even when non-empty"
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

variable "enable_vpc_cni_prefix_delegation" {
  description = "Enable VPC CNI prefix delegation for higher pod density"
  type        = bool
  default     = false
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
  default     = false
}
