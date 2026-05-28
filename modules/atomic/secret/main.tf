resource "ccp_secret" "this" {
  provider    = cetic-cloud-platform
  name        = var.name
  description = var.description
  data        = var.data
  tags        = var.tags
}
