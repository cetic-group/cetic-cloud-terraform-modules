resource "ccp_load_balancer" "this" {
  provider     = ccp
  name         = var.name
  region       = var.region
  plan         = var.plan
  vnet_id      = var.vnet_id
  public_ip_id = var.public_ip_id
  tags         = var.tags

  dynamic "listener" {
    for_each = var.listeners
    content {
      name          = listener.key
      algorithm     = listener.value.algorithm
      protocol      = listener.value.protocol
      frontend_port = listener.value.frontend_port

      dynamic "backend" {
        for_each = listener.value.backends
        content {
          container_id   = backend.value.container_id
          vm_instance_id = backend.value.vm_instance_id
          port           = backend.value.port
          weight         = backend.value.weight
        }
      }
    }
  }
}
