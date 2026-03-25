module "platform" {
  source = "../../../platforms/aws"

  cluster_name = var.cluster_name
  region       = var.region
  environment  = var.environment

  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  az_count           = var.az_count
  single_nat_gateway = var.single_nat_gateway

  kubernetes_version                   = var.kubernetes_version
  enable_cloudwatch_logging            = var.enable_cloudwatch_logging
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs

  general_min_size       = var.general_min_size
  general_max_size       = var.general_max_size
  general_desired_size   = var.general_desired_size
  general_instance_types = var.general_instance_types

  enable_storage_node_pool = var.enable_storage_node_pool
  storage_min_size         = var.storage_min_size
  storage_max_size         = var.storage_max_size
  storage_desired_size     = var.storage_desired_size
  storage_instance_types   = var.storage_instance_types
  enable_spot_instances    = var.enable_spot_instances

  create_backup_bucket             = var.create_backup_bucket
  force_destroy_backup_bucket      = var.force_destroy_backup_bucket
  backup_bucket_name               = var.backup_bucket_name
  backup_retention_days            = var.backup_retention_days
  enable_vpc_cni_prefix_delegation = var.enable_vpc_cni_prefix_delegation
}

module "database" {
  count  = var.database_provider == "managed" ? 1 : 0
  source = "../../../modules/aws-rds"

  project                = var.cluster_name
  environment            = var.environment
  database_name          = var.database_name
  database_owner         = var.database_username
  instance_class         = var.rds_instance_class
  engine_version         = var.rds_engine_version
  allocated_storage      = var.rds_allocated_storage
  max_allocated_storage  = var.rds_max_allocated_storage
  multi_az               = var.rds_multi_az
  vpc_id                 = module.platform.vpc_id
  private_subnet_ids     = module.platform.private_subnet_ids
  node_security_group_id = module.platform.node_security_group_id
  deletion_protection    = var.deletion_protection
}
