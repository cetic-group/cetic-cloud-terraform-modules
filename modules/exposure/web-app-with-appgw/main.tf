locals {
  hostnames_indexed = { for i, h in var.hostnames : tostring(i) => h }
}

# ── 1. Gateway ────────────────────────────────────────────────────────────────
module "gateway" {
  source = "../../atomic/application-gateway"

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

  tags = var.tags
}

# ── 2. Listeners (un par hostname) ───────────────────────────────────────────
resource "ccp_appgw_listener" "this" {
  for_each = local.hostnames_indexed

  appgw_id      = module.gateway.id
  hostname      = each.value
  custom_domain = var.custom_domain
}

# ── 3. Target groups (avec leurs members) ────────────────────────────────────
module "target_groups" {
  source   = "../../atomic/appgw-target-group"
  for_each = var.target_groups

  appgw_id = module.gateway.id
  name     = each.key

  algorithm          = each.value.algorithm
  health_check       = each.value.health_check
  sticky_enabled     = each.value.sticky_enabled
  sticky_cookie_name = each.value.sticky_cookie_name
  members            = each.value.members
}

# ── 4. Routes ────────────────────────────────────────────────────────────────
module "routes" {
  source = "../../atomic/appgw-route"
  count  = length(var.routes)

  appgw_id        = module.gateway.id
  listener_id     = ccp_appgw_listener.this[tostring(var.routes[count.index].listener_index)].id
  target_group_id = module.target_groups[var.routes[count.index].target_group_key].id

  priority        = var.routes[count.index].priority
  path_match      = var.routes[count.index].path_match
  path_match_type = var.routes[count.index].path_match_type
  method_match    = var.routes[count.index].method_match
  header_matches  = var.routes[count.index].header_matches

  rate_limit_per_sec    = var.routes[count.index].policies.rate_limit_per_sec
  allow_cidrs           = var.routes[count.index].policies.allow_cidrs
  deny_cidrs            = var.routes[count.index].policies.deny_cidrs
  request_headers       = var.routes[count.index].policies.request_headers
  response_headers      = var.routes[count.index].policies.response_headers
  cors_enabled          = var.routes[count.index].policies.cors_enabled
  cors_origins          = var.routes[count.index].policies.cors_origins
  cors_methods          = var.routes[count.index].policies.cors_methods
  cors_credentials      = var.routes[count.index].policies.cors_credentials
  basic_auth_secret_ref = var.routes[count.index].policies.basic_auth_secret_ref
  waf_preset            = var.routes[count.index].policies.waf_preset
}
