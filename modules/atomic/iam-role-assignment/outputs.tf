output "id" {
  description = "UUID of the role assignment."
  value       = ccp_iam_role_assignment.this.id
}

output "role_id" {
  description = "UUID of the attached role (echo of the input)."
  value       = ccp_iam_role_assignment.this.role_id
}

output "principal_type" {
  description = "Principal type — one of `org_member`, `api_key`, `service_account`, `ccks_workload`."
  value       = ccp_iam_role_assignment.this.principal_type
}

output "principal_id" {
  description = "UUID of the bound principal."
  value       = ccp_iam_role_assignment.this.principal_id
}

output "expires_at" {
  description = "RFC 3339 expiry timestamp, or `null` if the assignment does not expire."
  value       = ccp_iam_role_assignment.this.expires_at
}

output "created_at" {
  description = "RFC 3339 creation timestamp."
  value       = ccp_iam_role_assignment.this.created_at
}
