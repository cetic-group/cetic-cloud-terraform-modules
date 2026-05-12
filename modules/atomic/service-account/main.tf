resource "ccp_service_account" "this" {
  name        = var.name
  description = var.description
  expires_at  = var.expires_at
}
