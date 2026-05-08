resource "ccp_org_member" "this" {
  email = var.email
  role  = var.role
}
