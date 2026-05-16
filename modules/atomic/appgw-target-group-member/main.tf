resource "ccp_appgw_target_group_member" "this" {
  appgw_id        = var.appgw_id
  target_group_id = var.target_group_id

  container_id   = var.container_id
  vm_instance_id = var.vm_instance_id
  target_ip      = var.target_ip
  port           = var.port
  weight         = var.weight
  enabled        = var.enabled

  lifecycle {
    precondition {
      condition = (
        (var.container_id == null ? 0 : 1) +
        (var.vm_instance_id == null ? 0 : 1) +
        (var.target_ip == null ? 0 : 1)
      ) == 1
      error_message = "Exactement un de `container_id`, `vm_instance_id` ou `target_ip` doit être défini."
    }
  }
}
