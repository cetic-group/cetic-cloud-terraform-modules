resource "ccp_appgw_listener" "this" {
  l7_policy = var.l7_policy
  provider  = ccp

  appgw_id             = var.appgw_id
  hostname             = var.hostname
  acme_challenge       = var.acme_challenge
  acme_dns_provider    = var.acme_dns_provider
  acme_dns_credentials = var.acme_dns_credentials
}
