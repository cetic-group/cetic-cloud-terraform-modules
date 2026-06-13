resource "ccp_windows_instance" "this" {
  provider               = ccp
  name                   = var.name
  region                 = var.region
  plan                   = var.plan
  template               = var.template
  vnet_id                = var.vnet_id
  public_ip_id           = var.public_ip_id
  administrator_password = var.administrator_password
  data_volume_ids        = var.data_volume_ids
  tags                   = var.tags
}
