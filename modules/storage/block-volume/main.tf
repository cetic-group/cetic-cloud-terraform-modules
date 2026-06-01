locals {
  _attach_type = try(var.attach_to.type, null)
  # Le provider attend `vm` depuis v0.24+ (TypeName aligné). On mappe l'alias
  # legacy `vm_instance` → `vm` pour rester rétro-compatible (fix v0.17.1).
  attached_to_type = local._attach_type == "vm_instance" ? "vm" : local._attach_type
}

resource "ccp_block_volume" "this" {
  provider         = ccp
  name             = var.name
  region           = var.region
  size_gb          = var.size_gb
  attached_to_id   = try(var.attach_to.id, null)
  attached_to_type = local.attached_to_type
  tags             = var.tags
}
