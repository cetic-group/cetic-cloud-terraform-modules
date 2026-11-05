resource "ccp_db_pg_instance" "this" {
  provider       = ccp
  name           = var.name
  region         = var.region
  vpc_id         = var.vpc_id
  vnet_id        = var.vnet_id
  plan           = var.plan
  storage_gb     = var.storage_gb
  replicas       = var.replicas
  engine_version = var.engine_version
  tags           = var.tags

  allowed_extensions = var.allowed_extensions
  preload_libraries  = var.preload_libraries
  cron_database      = var.cron_database
}
