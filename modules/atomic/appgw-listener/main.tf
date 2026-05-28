resource "ccp_appgw_listener" "this" {
  provider      = cetic-cloud-platform
  appgw_id      = var.appgw_id
  hostname      = var.hostname
  custom_domain = var.custom_domain
}
