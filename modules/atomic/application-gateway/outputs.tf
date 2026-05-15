output "id" {
  description = "UUID de l'Application Gateway."
  value       = ccp_application_gateway.this.id
}

output "name" {
  description = "Nom de l'AppGW."
  value       = ccp_application_gateway.this.name
}

output "status" {
  description = "Statut courant : `creating`, `active`, `error`, `deleting`."
  value       = ccp_application_gateway.this.status
}

output "vip_address" {
  description = "VIP privée flottante de la gateway (dans le VNet)."
  value       = ccp_application_gateway.this.vip_address
}

output "public_ip_address" {
  description = "IP publique attachée, ou `null` si gateway interne."
  value       = ccp_application_gateway.this.public_ip_address
}

output "plan" {
  description = "Plan effectif appliqué (`small` / `medium` / `large`)."
  value       = ccp_application_gateway.this.plan
}

output "region" {
  description = "Région de la gateway."
  value       = ccp_application_gateway.this.region
}
