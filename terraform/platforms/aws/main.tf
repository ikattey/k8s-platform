locals {
  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Cluster     = var.cluster_name
  })
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0"

  name               = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.intra_subnets

  endpoint_public_access       = var.cluster_endpoint_public_access
  endpoint_private_access      = var.cluster_endpoint_private_access
  endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  enable_cluster_creator_admin_permissions = true
  access_entries                           = var.access_entries

  create_cloudwatch_log_group            = var.enable_cloudwatch_logging
  cloudwatch_log_group_retention_in_days = 30
  enabled_log_types                      = var.enable_cloudwatch_logging ? ["api", "audit", "authenticator", "controllerManager", "scheduler"] : []

  enable_irsa = true

  addons = local.cluster_addons

  eks_managed_node_groups = local.eks_managed_node_groups

  tags = local.tags
}
