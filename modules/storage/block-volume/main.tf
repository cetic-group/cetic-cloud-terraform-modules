resource "ccp_block_volume" "this" {
  provider         = cetic-cloud-platform
  name             = var.name
  region           = var.region
  size_gb          = var.size_gb
  attached_to_id   = try(var.attach_to.id, null)
  attached_to_type = try(var.attach_to.type, null)
  tags             = var.tags
}
