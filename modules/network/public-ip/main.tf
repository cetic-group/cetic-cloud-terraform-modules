resource "ccp_public_ip" "this" {
  region  = var.region
  pool_id = var.pool_id
}
