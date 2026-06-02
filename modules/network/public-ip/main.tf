resource "ccp_public_ip" "this" {
  count    = var.quantity
  provider = ccp

  region      = var.region
  pool_id     = var.pool_id
  label       = var.label == null ? null : (var.quantity > 1 ? "${var.label}-${count.index + 1}" : var.label)
  description = var.description
}
