output "id" {
  description = "Subscription row UUID."
  value       = ccp_support_subscription.this.id
}

output "tenant_id" {
  description = "Tenant UUID."
  value       = ccp_support_subscription.this.tenant_id
}

output "plan_key" {
  description = "Effective plan key (mirrors input)."
  value       = ccp_support_subscription.this.plan_key
}

output "started_at" {
  description = "RFC3339 timestamp when this subscription started."
  value       = ccp_support_subscription.this.started_at
}

output "display_name" {
  description = "Human-readable plan name (resolved from catalogue)."
  value       = data.ccp_support_plan.this.display_name
}

output "price_eur_month" {
  description = "Monthly price in EUR (0 for free plans)."
  value       = data.ccp_support_plan.this.price_eur_month
}

output "sla_first_response_hours" {
  description = "First-response SLA in hours."
  value       = data.ccp_support_plan.this.sla_first_response_hours
}

output "sla_resolution_hours" {
  description = "Resolution SLA in hours (0 = best-effort)."
  value       = data.ccp_support_plan.this.sla_resolution_hours
}

output "max_priority" {
  description = "Maximum ticket priority allowed by the plan."
  value       = data.ccp_support_plan.this.max_priority
}

output "channels" {
  description = "Supported support channels."
  value       = data.ccp_support_plan.this.channels
}
