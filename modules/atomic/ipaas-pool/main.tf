resource "ccp_ipaas_pool" "this" {
  region    = var.region
  cidr      = var.cidr
  gateway   = var.gateway
  edge_id   = var.edge_id
  is_active = var.is_active
}
