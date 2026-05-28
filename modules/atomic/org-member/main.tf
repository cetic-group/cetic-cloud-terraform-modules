resource "ccp_org_member" "this" {
  provider = cetic-cloud-platform
  email    = var.email
  role     = var.role
}
