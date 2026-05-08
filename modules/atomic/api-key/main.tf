resource "ccp_api_key" "this" {
  name            = var.name
  scopes          = var.scopes
  expires_in_days = var.expires_in_days
}
