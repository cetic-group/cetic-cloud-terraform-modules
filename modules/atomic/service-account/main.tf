resource "ccp_service_account" "this" {
  provider    = ccp
  name        = var.name
  description = var.description
  expires_at  = var.expires_at
}
