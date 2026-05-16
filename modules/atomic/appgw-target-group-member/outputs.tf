output "id" {
  description = "UUID du member."
  value       = ccp_appgw_target_group_member.this.id
}

output "appgw_id" {
  description = "UUID de la gateway parente."
  value       = ccp_appgw_target_group_member.this.appgw_id
}

output "target_group_id" {
  description = "UUID du target group parent."
  value       = ccp_appgw_target_group_member.this.target_group_id
}

output "port" {
  description = "Port effectif."
  value       = ccp_appgw_target_group_member.this.port
}

output "weight" {
  description = "Pondération effective."
  value       = ccp_appgw_target_group_member.this.weight
}

output "enabled" {
  description = "État administratif (`true` = actif)."
  value       = ccp_appgw_target_group_member.this.enabled
}
