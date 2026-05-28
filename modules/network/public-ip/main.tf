resource "ccp_public_ip" "this" {
  provider = cetic-cloud-platform
  region   = var.region
  pool_id  = var.pool_id
}
