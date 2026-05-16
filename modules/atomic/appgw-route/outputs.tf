output "id" {
  description = "UUID de la route."
  value       = ccp_appgw_route.this.id
}

output "appgw_id" {
  description = "UUID de la gateway parente."
  value       = ccp_appgw_route.this.appgw_id
}

output "listener_id" {
  description = "UUID du listener associé."
  value       = ccp_appgw_route.this.listener_id
}

output "target_group_id" {
  description = "UUID du target group cible."
  value       = ccp_appgw_route.this.target_group_id
}

output "priority" {
  description = "Priorité effective."
  value       = ccp_appgw_route.this.priority
}

output "basic_auth_secret_ref" {
  description = <<-EOT
    Référence opaque du Secret Manager backing les credentials basic auth (ou `null` si
    `basic_auth_users` est vide). Ce n'est pas un mot de passe — c'est un identifiant interne,
    non exploitable seul, donc non sensitive.
  EOT
  value       = ccp_appgw_route.this.basic_auth_secret_ref
  sensitive   = false
}
