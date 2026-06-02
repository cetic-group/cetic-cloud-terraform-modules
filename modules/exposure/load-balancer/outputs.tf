output "id" {
  description = "UUID du load balancer."
  value       = ccp_load_balancer.this.id
}

output "vip_address" {
  description = "VIP privée du LB (dans le VNet)."
  value       = ccp_load_balancer.this.vip_address
}

output "public_ip_address" {
  description = "IP publique attachée, ou chaîne vide."
  value       = ccp_load_balancer.this.public_ip_address
}

output "status" {
  description = "Statut courant : `provisioning`, `active`, `updating`, `error`."
  value       = ccp_load_balancer.this.status
}

output "created_at" {
  description = "Timestamp RFC 3339 de création du LB."
  value       = ccp_load_balancer.this.created_at
}
