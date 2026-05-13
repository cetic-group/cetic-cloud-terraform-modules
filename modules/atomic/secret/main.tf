resource "ccp_secret" "this" {
  name        = var.name
  description = var.description
  data        = var.data
  tags        = var.tags
}
