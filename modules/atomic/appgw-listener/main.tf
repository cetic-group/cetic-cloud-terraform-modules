resource "ccp_appgw_listener" "this" {
  appgw_id      = var.appgw_id
  hostname      = var.hostname
  custom_domain = var.custom_domain
}
