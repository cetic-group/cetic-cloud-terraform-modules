# ── Outputs singuliers (rétro-compatibles — pointent sur la 1re IP) ───────────

output "id" {
  description = "UUID de la 1re IP publique. À passer dans `public_ip_id` d'un container/VM/LB."
  value       = ccp_public_ip.this[0].id
}

output "ip_address" {
  description = "L'adresse IP publique allouée (1re IP)."
  value       = ccp_public_ip.this[0].ip_address
}

output "status" {
  description = "Statut courant de la 1re IP : `available`, `allocated`, `attached`, `reserved`."
  value       = ccp_public_ip.this[0].status
}

output "attached_to_id" {
  description = "UUID de la ressource à laquelle la 1re IP est attachée (container/VM), ou `null`."
  value       = ccp_public_ip.this[0].attached_to_id
}

output "attached_to_type" {
  description = "Type de ressource attachée à la 1re IP : `container`, `vm_instance`, ou `null`."
  value       = ccp_public_ip.this[0].attached_to_type
}

output "label" {
  description = "Label de la 1re IP (suffixé `-1` si `quantity > 1`), ou `null`."
  value       = ccp_public_ip.this[0].label
}

output "description" {
  description = "Description de la 1re IP, ou `null`."
  value       = ccp_public_ip.this[0].description
}

# ── Outputs liste (toutes les IPs allouées) ───────────────────────────────────

output "ids" {
  description = "Liste des UUID de toutes les IPs publiques allouées."
  value       = ccp_public_ip.this[*].id
}

output "ip_addresses" {
  description = "Liste des adresses IP publiques allouées."
  value       = ccp_public_ip.this[*].ip_address
}

output "labels" {
  description = "Liste des labels (suffixés `-1`, `-2`, … si `quantity > 1`)."
  value       = ccp_public_ip.this[*].label
}
