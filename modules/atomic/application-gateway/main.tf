resource "ccp_application_gateway" "this" {
  provider     = cetic-cloud-platform
  name         = var.name
  region       = var.region
  plan         = var.plan
  vpc_id       = var.vpc_id
  vnet_id      = var.vnet_id
  public_ip_id = var.public_ip_id

  force_https               = var.force_https
  hsts_enabled              = var.hsts_enabled
  hsts_max_age              = var.hsts_max_age
  global_rate_limit_per_sec = var.global_rate_limit_per_sec
  global_allow_cidrs        = var.global_allow_cidrs
  global_deny_cidrs         = var.global_deny_cidrs
  trust_proxy_headers       = var.trust_proxy_headers

  tags = var.tags
}
