resource "ccp_custom_template" "this" {
  provider            = ccp
  name                = var.name
  description         = var.description
  source_container_id = var.source_container_id
  source_vm_id        = var.source_vm_id
}
