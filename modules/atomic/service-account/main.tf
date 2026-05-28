resource "ccp_service_account" "this" {
  provider    = cetic-cloud-platform
  name        = var.name
  description = var.description
  expires_at  = var.expires_at
}
