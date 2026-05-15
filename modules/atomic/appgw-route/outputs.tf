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
