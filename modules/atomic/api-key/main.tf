resource "ccp_api_key" "this" {
  provider        = cetic-cloud-platform
  name            = var.name
  scopes          = var.scopes
  expires_in_days = var.expires_in_days
}
