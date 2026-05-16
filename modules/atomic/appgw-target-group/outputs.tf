output "id" {
  description = "UUID du target group."
  value       = ccp_appgw_target_group.this.id
}

output "name" {
  description = "Nom du target group."
  value       = ccp_appgw_target_group.this.name
}

output "appgw_id" {
  description = "UUID de la gateway parente."
  value       = ccp_appgw_target_group.this.appgw_id
}

output "algorithm" {
  description = "Algorithme effectif."
  value       = ccp_appgw_target_group.this.algorithm
}

output "member_ids" {
  description = "Map keyed par label logique → UUID du member."
  value       = { for k, v in ccp_appgw_target_group_member.members : k => v.id }
}
