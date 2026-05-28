resource "ccp_iam_role" "this" {
  provider             = cetic-cloud-platform
  name                 = var.name
  description          = var.description
  policy_document_json = var.policy_document_json
}
