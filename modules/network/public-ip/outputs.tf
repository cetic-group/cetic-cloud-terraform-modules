output "id" {
  description = "UUID de l'IP publique. À passer dans `public_ip_id` d'un container/VM/LB."
  value       = ccp_public_ip.this.id
}

output "ip_address" {
  description = "L'adresse IP publique allouée."
  value       = ccp_public_ip.this.ip_address
}

output "status" {
  description = "Statut courant : `available`, `attached`, `attaching`, `detaching`, `error`."
  value       = ccp_public_ip.this.status
}

output "attached_to_id" {
  description = "UUID de la ressource à laquelle l'IP est attachée (container/VM/LB), ou `null`."
  value       = ccp_public_ip.this.attached_to_id
}

output "attached_to_type" {
  description = "Type de ressource attachée : `container`, `vm_instance`, `load_balancer`, ou `null`."
  value       = ccp_public_ip.this.attached_to_type
}
