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

output "kind" {
  description = "Type effectif du target group : `upstream` ou `bucket`."
  value       = ccp_appgw_target_group.this.kind
}

output "origin_status" {
  description = "État de l'origine d'un target group `bucket` : `ok`, `drift` (bucket redevenu privé ou introuvable, voir `origin_error`) ou null (pas encore vérifié, ou `upstream`)."
  value       = ccp_appgw_target_group.this.origin_status
}

output "origin_error" {
  description = "Détail du problème d'origine d'un target group `bucket` en état `drift` ; null sinon."
  value       = ccp_appgw_target_group.this.origin_error
}

output "bucket_id" {
  description = "UUID du bucket servi (target group `bucket`), sinon null."
  value       = ccp_appgw_target_group.this.bucket_id
}

output "bucket_prefix" {
  description = "Dossier du bucket servi (target group `bucket`), vide pour tout le bucket."
  value       = ccp_appgw_target_group.this.bucket_prefix
}
