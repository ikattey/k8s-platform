variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name"
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

variable "single_nat_gateway" {
  description = "Use a single NAT gateway to reduce starter costs"
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
  description = "CIDRs allowed to reach the public EKS endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "general_min_size" {
  description = "Minimum general node group size"
  type        = number
  default     = 2
}

variable "general_max_size" {
  description = "Maximum general node group size"
  type        = number
  default     = 6
}

variable "general_desired_size" {
  description = "Desired general node group size"
  type        = number
  default     = 3
}

variable "general_instance_types" {
  description = "General node group instance types"
  type        = list(string)
  default     = ["m5.large", "m5a.large", "m6i.large", "m6a.large"]
}

variable "storage_enabled" {
  description = "Create a dedicated storage node group. Enable when running CNPG or other stateful workloads that need dedicated storage nodes."
  type        = bool
  default     = false
}

variable "storage_min_size" {
  description = "Minimum storage node group size"
  type        = number
  default     = 1
}

variable "storage_max_size" {
  description = "Maximum storage node group size"
  type        = number
  default     = 2
}

variable "storage_desired_size" {
  description = "Desired storage node group size"
  type        = number
  default     = 1
}

variable "storage_instance_types" {
  description = "Storage node group instance types"
  type        = list(string)
  default     = ["m5.large"]
}

variable "create_backup_bucket" {
  description = "Create an S3 bucket for Loki and CNPG"
  type        = bool
  default     = true
}

variable "backup_bucket_name" {
  description = "Existing or desired backup bucket name; leave empty for auto-generated"
  type        = string
  default     = ""
}

variable "backup_retention_days" {
  description = "Lifecycle retention for the backup bucket"
  type        = number
  default     = 30
}

variable "access_entries" {
  description = "Optional access entries for EKS cluster authentication"
  type = map(object({
    principal_arn     = string
    kubernetes_groups = optional(list(string), [])
    policy_associations = optional(map(object({
      policy_arn = string
      access_scope = object({
        type       = string
        namespaces = optional(list(string), [])
      })
    })), {})
  }))
  default = {}
}

variable "enable_spot_instances" {
  description = "Use Spot instances for the general node pool. Enable for cost savings. Not recommended for platform-layer nodes."
  type        = bool
  default     = false
}

variable "az_count" {
  description = "Number of availability zones to use when availability_zones is not set"
  type        = number
  default     = 2
}

variable "enable_cloudwatch_logging" {
  description = "Send EKS control plane logs to CloudWatch. Off by default (use Loki). Enable for audit compliance."
  type        = bool
  default     = false
}

variable "force_destroy_backup_bucket" {
  description = "Allow Terraform to destroy the backup bucket even when non-empty"
  type        = bool
  default     = true
}

variable "enable_vpc_cni_prefix_delegation" {
  description = "Enable VPC CNI prefix delegation for higher pod density"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional AWS tags"
  type        = map(string)
  default     = {}
}
