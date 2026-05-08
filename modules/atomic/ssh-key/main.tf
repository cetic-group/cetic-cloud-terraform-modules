resource "ccp_ssh_key" "this" {
  name       = var.name
  public_key = var.public_key
}
