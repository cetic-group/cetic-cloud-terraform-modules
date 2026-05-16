output "budget_id" {
  description = "ID of the ccp_budget resource."
  value       = ccp_budget.this.id
}

output "monthly_budget_cents" {
  description = "Cap in EUR cents."
  value       = ccp_budget.this.monthly_budget_cents
}

output "last_alert_threshold_pct" {
  description = "Most recent threshold that triggered an alert this month, or null."
  value       = ccp_budget.this.last_alert_threshold_pct
}

output "commit_id" {
  description = "ID of the ccp_commit resource, or null if no commit was subscribed."
  value       = try(ccp_commit.this[0].id, null)
}

output "commit_discount_pct" {
  description = "Active commitment discount percentage, or null."
  value       = try(ccp_commit.this[0].discount_pct, null)
}

output "commit_end_at" {
  description = "Commitment end timestamp (RFC3339), or null."
  value       = try(ccp_commit.this[0].end_at, null)
}
