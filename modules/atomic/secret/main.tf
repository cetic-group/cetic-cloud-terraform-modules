resource "ccp_secret" "this" {
  provider    = ccp
  name        = var.name
  description = var.description
  data        = var.data
  tags        = var.tags
}
