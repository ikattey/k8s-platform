locals {
  tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
    Cluster     = var.cluster_name
  })
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  private_subnets = [for idx, _ in var.availability_zones : cidrsubnet(var.vpc_cidr, 4, idx)]
  public_subnets  = [for idx, _ in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, idx + 48)]
  intra_subnets   = [for idx, _ in var.availability_zones : cidrsubnet(var.vpc_cidr, 8, idx + 52)]

  enable_nat_gateway   = true
  single_nat_gateway   = var.single_nat_gateway
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  enable_cluster_creator_admin_permissions = false
  access_entries                           = var.access_entries

  create_cloudwatch_log_group = false

  enable_irsa = true

  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    vpc-cni    = {}
    aws-ebs-csi-driver = {
      service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
    }
  }

  tags = local.tags
}
