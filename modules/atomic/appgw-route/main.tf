resource "ccp_appgw_route" "this" {
  appgw_id        = var.appgw_id
  listener_id     = var.listener_id
  target_group_id = var.target_group_id

  priority        = var.priority
  path_match      = var.path_match
  path_match_type = var.path_match_type

  dynamic "header_match" {
    for_each = var.header_matches
    content {
      name  = header_match.value.name
      value = header_match.value.value
      op    = header_match.value.op
    }
  }

  method_match = var.method_match

  # Policies
  rate_limit_per_sec = var.rate_limit_per_sec
  allow_cidrs        = var.allow_cidrs
  deny_cidrs         = var.deny_cidrs
  request_headers    = var.request_headers
  response_headers   = var.response_headers
  cors_enabled       = var.cors_enabled
  cors_origins       = var.cors_origins
  cors_methods       = var.cors_methods
  cors_credentials   = var.cors_credentials
  waf_preset         = var.waf_preset

  # Basic auth: each block becomes one credential pair on the route.
  # Plaintext passwords are persisted in the Terraform state and hashed
  # server-side into a Secret Manager entry exposed via the computed
  # `basic_auth_secret_ref` attribute (output below).
  dynamic "basic_auth_user" {
    for_each = var.basic_auth_users == null ? [] : var.basic_auth_users
    content {
      user     = basic_auth_user.value.user
      password = basic_auth_user.value.password
    }
  }

  lifecycle {
    precondition {
      condition     = !(var.cors_credentials && contains(var.cors_origins, "*"))
      error_message = "CORS : `cors_credentials=true` est incompatible avec `cors_origins=[\"*\"]` (les navigateurs refusent ce combo)."
    }
  }
}
