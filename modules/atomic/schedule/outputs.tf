output "id" {
  description = "UUID assigné par le serveur au planning."
  value       = ccp_schedule.this.id
}

output "current_state" {
  description = "Dernier état d'alimentation désiré appliqué par la plateforme : `on` ou `off`."
  value       = ccp_schedule.this.current_state
}

output "last_transition_at" {
  description = "Timestamp RFC 3339 de la dernière transition d'alimentation, ou null si aucune."
  value       = ccp_schedule.this.last_transition_at
}

output "estimated_monthly_fee_cents" {
  description = "Frais mensuels estimés du scheduler en centimes (nombre d'instances pilotées × tarif par instance)."
  value       = ccp_schedule.this.estimated_monthly_fee_cents
}
