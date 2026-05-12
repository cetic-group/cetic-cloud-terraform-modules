output "id" {
  description = "Server-assigned UUID of the IAM role."
  value       = ccp_iam_role.this.id
}

output "role_id" {
  description = "Alias of `id` — UUID of the IAM role. Convenient when chaining with `ccp_iam_role_assignment.role_id`."
  value       = ccp_iam_role.this.id
}

output "role_name" {
  description = "Human-readable name of the IAM role."
  value       = ccp_iam_role.this.name
}

output "role_arn" {
  description = <<-EOT
    Convenience-computed ARN of the role using the CETIC Cloud ARN scheme:
    `arn:ccp:iam::<tenant_id>:role/<role_name>`. Built-in roles have an empty
    `tenant_id` segment; custom roles always reference the caller's tenant.

    Note: `tenant_id` is left empty here — the API resolves it server-side at
    evaluation time. Use it as a hint in logs/audit; not as a lookup key.
  EOT
  value       = "arn:ccp:iam:::role/${ccp_iam_role.this.name}"
}

output "policy_hash" {
  description = "SHA-256 hex of the canonical PolicyDocument — useful for drift detection."
  value       = ccp_iam_role.this.policy_hash
}

output "policy_document_json" {
  description = "Canonicalised PolicyDocument as returned by the API (sorted keys, no whitespace)."
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
