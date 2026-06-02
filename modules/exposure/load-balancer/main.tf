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
      protocol             = listener.value.protocol
      listen_port          = listener.value.listen_port
      algorithm            = listener.value.algorithm
      health_check_enabled = listener.value.health_check_enabled
      health_check_path    = listener.value.health_check_path
      domain               = listener.value.domain
      acme_challenge       = listener.value.acme_challenge
      acme_dns_provider    = listener.value.acme_dns_provider
      acme_dns_credentials = listener.value.acme_dns_credentials

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
