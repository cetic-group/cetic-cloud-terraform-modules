resource "ccp_iam_role_assignment" "this" {
  provider       = ccp
  role_id        = var.role_id
  principal_type = var.principal_type
  principal_id   = var.principal_id
  expires_at     = var.expires_at
}
