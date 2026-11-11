locals {
  is_bucket = var.kind == "bucket"
}

resource "ccp_appgw_target_group" "this" {
  provider  = ccp
  appgw_id  = var.appgw_id
  name      = var.name
  algorithm = local.is_bucket ? null : var.algorithm

  hc_protocol            = local.is_bucket ? null : var.health_check.protocol
  hc_method              = local.is_bucket ? null : var.health_check.method
  hc_path                = local.is_bucket ? null : var.health_check.path
  hc_expect_status       = local.is_bucket ? null : var.health_check.expect_status
  hc_interval_sec        = local.is_bucket ? null : var.health_check.interval_sec
  hc_timeout_sec         = local.is_bucket ? null : var.health_check.timeout_sec
  hc_healthy_threshold   = local.is_bucket ? null : var.health_check.healthy_threshold
  hc_unhealthy_threshold = local.is_bucket ? null : var.health_check.unhealthy_threshold

  sticky_enabled     = local.is_bucket ? null : var.sticky_enabled
  sticky_cookie_name = local.is_bucket ? null : var.sticky_cookie_name

  kind          = var.kind
  bucket_id     = var.bucket_id
  bucket_prefix = var.bucket_prefix

  lifecycle {
    precondition {
      condition     = var.kind != "bucket" || var.bucket_id != null
      error_message = "`bucket_id` est requis quand `kind = \"bucket\"`."
    }
    precondition {
      condition     = var.kind == "bucket" || (var.bucket_id == null && var.bucket_prefix == "")
      error_message = "`bucket_id` et `bucket_prefix` ne s'appliquent qu'à `kind = \"bucket\"`."
    }
    precondition {
      condition     = var.kind != "bucket" || (length(var.members) == 0 && !var.sticky_enabled)
      error_message = "Un target group `kind = \"bucket\"` n'a ni `members` ni session persistante (`sticky_enabled`)."
    }
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
