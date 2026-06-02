resource "ccp_appgw_listener" "this" {
  provider = ccp

  appgw_id             = var.appgw_id
  hostname             = var.hostname
  acme_challenge       = var.acme_challenge
  acme_dns_provider    = var.acme_dns_provider
  acme_dns_credentials = var.acme_dns_credentials
}
