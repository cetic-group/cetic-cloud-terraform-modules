output "id" {
  description = "UUID of the IAM role."
  value       = ccp_iam_role.this.id
}

output "name" {
  description = "Name of the IAM role."
  value       = ccp_iam_role.this.name
}

output "policy_hash" {
  description = "SHA-256 hex of the canonical PolicyDocument."
  value       = ccp_iam_role.this.policy_hash
}

output "policy_document_json" {
  description = "Canonicalised PolicyDocument as returned by the API."
  value       = ccp_iam_role.this.policy_document_json
}

output "is_built_in" {
  description = "Always `false` for roles created by this module."
  value       = ccp_iam_role.this.is_built_in
}

output "created_at" {
  description = "RFC 3339 creation timestamp."
  value       = ccp_iam_role.this.created_at
}

output "updated_at" {
  description = "RFC 3339 timestamp of the last update."
  value       = ccp_iam_role.this.updated_at
}
