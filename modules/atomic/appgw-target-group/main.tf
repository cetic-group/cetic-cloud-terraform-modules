resource "ccp_appgw_target_group" "this" {
  provider  = ccp
  appgw_id  = var.appgw_id
  name      = var.name
  algorithm = var.algorithm

  hc_protocol            = var.health_check.protocol
  hc_method              = var.health_check.method
  hc_path                = var.health_check.path
  hc_expect_status       = var.health_check.expect_status
  hc_interval_sec        = var.health_check.interval_sec
  hc_timeout_sec         = var.health_check.timeout_sec
  hc_healthy_threshold   = var.health_check.healthy_threshold
  hc_unhealthy_threshold = var.health_check.unhealthy_threshold

  sticky_enabled     = var.sticky_enabled
  sticky_cookie_name = var.sticky_cookie_name

  lifecycle {
    precondition {
      condition     = !var.sticky_enabled || var.sticky_cookie_name != null
      error_message = "`sticky_cookie_name` est requis quand `sticky_enabled=true`."
    }
  }
}

resource "ccp_appgw_target_group_member" "members" {
  provider = ccp
  for_each = var.members

  appgw_id        = var.appgw_id
  target_group_id = ccp_appgw_target_group.this.id

  container_id   = each.value.container_id
  vm_instance_id = each.value.vm_instance_id
  target_ip      = each.value.target_ip
  port           = each.value.port
  weight         = each.value.weight
  enabled        = each.value.enabled
}
