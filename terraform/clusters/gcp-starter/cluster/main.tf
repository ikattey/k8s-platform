module "platform" {
  source = "../../../platforms/gcp"

  project_id   = var.project_id
  cluster_name = var.cluster_name
  environment  = var.environment

  region   = var.region
  location = var.location

  subnet_cidr   = var.subnet_cidr
  pods_cidr     = var.pods_cidr
  services_cidr = var.services_cidr

  node_count     = var.node_count
  max_node_count = var.max_node_count
  machine_type   = var.machine_type
  spot           = var.spot
  disk_size_gb   = var.disk_size_gb

  enable_storage_node_pool = var.enable_storage_node_pool
  storage_node_count       = var.storage_node_count
  storage_max_node_count   = var.storage_max_node_count
  storage_machine_type     = var.storage_machine_type
  storage_spot             = var.storage_spot
  storage_disk_size_gb     = var.storage_disk_size_gb

  create_backup_bucket  = var.create_backup_bucket
  backup_bucket_name    = var.backup_bucket_name
  backup_retention_days = var.backup_retention_days

  deletion_protection           = var.deletion_protection
  master_authorized_cidr_blocks = var.master_authorized_cidr_blocks

  maintenance_recurrence = var.maintenance_recurrence
  maintenance_start_time = var.maintenance_start_time
  maintenance_end_time   = var.maintenance_end_time

  disk_type         = var.disk_type
  storage_disk_type = var.storage_disk_type
}

module "database" {
  count  = var.database_provider == "managed" ? 1 : 0
  source = "../../../modules/gcp-cloud-sql"

  project_id          = var.project_id
  region              = var.region
  network_self_link   = module.platform.network_self_link
  instance_name       = "${var.cluster_name}-postgres"
  database_name       = var.database_name
  database_user       = var.database_username
  tier                = var.cloud_sql_tier
  disk_size_gb        = var.cloud_sql_disk_size_gb
  availability_type   = var.cloud_sql_availability_type
  environment         = var.environment
  deletion_protection = var.deletion_protection
}
