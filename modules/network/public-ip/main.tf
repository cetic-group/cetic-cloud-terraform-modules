resource "ccp_public_ip" "this" {
  provider = ccp
  region   = var.region
  pool_id  = var.pool_id
}
