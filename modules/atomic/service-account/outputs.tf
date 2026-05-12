output "id" {
  description = "UUID of the service account. Use this as `principal_id` in `ccp_iam_role_assignment` with `principal_type = \"service_account\"`."
  value       = ccp_service_account.this.id
}

output "name" {
  description = "Name of the service account."
  value       = ccp_service_account.this.name
}

output "token_prefix" {
  description = "Visible token prefix (`ccp_sa_xxxxxxxx`) — safe to log / store in non-secret contexts."
  value       = ccp_service_account.this.token_prefix
}

output "token" {
  description = <<-EOT
    Full service account token (`ccp_sa_<43 chars>`). **Sensible** — visible only at creation,
    never re-emitted by the API. Persisted in the Terraform state. Keep your state backend secure.

    To rotate, `terraform taint module.<this>.ccp_service_account.this` then `terraform apply`
    — the destroy + re-create cycle issues a fresh token.
  EOT
  value       = ccp_service_account.this.token
  sensitive   = true
}

output "expires_at" {
  description = "RFC 3339 expiry timestamp, or `null` if no expiry."
  value       = ccp_service_account.this.expires_at
}

output "last_used_at" {
  description = "RFC 3339 timestamp of the last successful auth with this token, or `null`."
  value       = ccp_service_account.this.last_used_at
}

output "rotated_at" {
  description = "RFC 3339 timestamp of the last server-side rotation. Always `null` for SAs managed via Terraform (rotation goes through taint)."
  value       = ccp_service_account.this.rotated_at
}

output "created_at" {
  description = "RFC 3339 creation timestamp."
  value       = ccp_service_account.this.created_at
}
