output "service_account_ids" {
  description = "Map env → UUID of the CI service account (`ci-<env>`)."
  value       = { for k, m in module.ci_sa : k => m.id }
}

output "service_account_tokens" {
  description = <<-EOT
    Map env → full service account token (`ccp_sa_*`). **Sensible** — visible only at creation,
    never re-emitted by the API. Persisted in the Terraform state.

    Copy each token to your CI provider's secrets (GitHub Actions, GitLab CI, etc.) at the time
    of `terraform apply`. To rotate, taint the relevant `module.ci_sa[<env>].ccp_service_account.this`.
  EOT
  value       = { for k, m in module.ci_sa : k => m.token }
  sensitive   = true
}

output "service_account_token_prefixes" {
  description = "Map env → visible token prefix (`ccp_sa_xxxxxxxx`) — safe to log / display in dashboards."
  value       = { for k, m in module.ci_sa : k => m.token_prefix }
}

output "registry_deployer_role_ids" {
  description = "Map env → UUID of the per-env `RegistryDeployer-<env>` role."
  value       = { for k, m in module.registry_deployer : k => m.role_id }
}

output "billing_viewer_role_id" {
  description = "UUID of the cross-env `BillingViewer` role (always created, even if no assignment)."
  value       = module.billing_viewer.role_id
}

output "billing_viewer_assignment_id" {
  description = "UUID of the BillingViewer ↔ org_member assignment, or `null` if `billing_viewer_member_id` was not provided."
  value       = length(module.billing_viewer_member) > 0 ? module.billing_viewer_member[0].id : null
}
