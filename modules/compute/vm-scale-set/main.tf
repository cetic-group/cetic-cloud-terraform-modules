resource "ccp_vm_scale_set" "this" {
  provider          = ccp
  name              = var.name
  region            = var.region
  plan              = var.plan
  template          = var.template
  vnet_id           = var.vnet_id
  min_instances     = var.min_instances
  max_instances     = var.max_instances
  desired_instances = var.desired_instances
  auto_repair       = var.auto_repair
  root_password     = var.root_password
  disk_gb           = var.disk_gb
  bastion_access    = var.bastion_access
  tags              = var.tags

  windows_license_consent = var.windows_license_consent
}
