resource "ccp_org_member" "this" {
  provider = ccp
  email    = var.email
  role     = var.role
}
