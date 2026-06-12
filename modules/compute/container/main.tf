resource "ccp_container_instance" "this" {
  provider       = ccp
  name           = var.name
  region         = var.region
  plan           = var.plan
  template       = var.template
  vnet_id        = var.vnet_id
  ssh_key_ids    = var.ssh_key_ids
  user_data      = var.user_data
  public_ip_id   = var.public_ip_id
  root_password  = var.root_password
  bastion_access = var.bastion_access
  tags           = var.tags
}
