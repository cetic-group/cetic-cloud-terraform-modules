resource "ccp_ssh_key" "this" {
  provider   = cetic-cloud-platform
  name       = var.name
  public_key = var.public_key
  scope      = var.scope
}
