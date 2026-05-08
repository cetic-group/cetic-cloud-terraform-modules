output "id" {
  description = "UUID du load balancer."
  value       = ccp_load_balancer.this.id
}

output "vip_address" {
  description = "VIP privée du LB (dans le VNet)."
  value       = ccp_load_balancer.this.vip_address
}

output "public_ip_address" {
  description = "IP publique attachée, ou `null`."
  value       = ccp_load_balancer.this.public_ip_address
}

output "status" {
  description = "Statut courant : `provisioning`, `active`, `error`, `deleting`."
  value       = ccp_load_balancer.this.status
}
