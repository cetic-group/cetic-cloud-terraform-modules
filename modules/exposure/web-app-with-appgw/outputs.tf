output "appgw_id" {
  description = "UUID de l'Application Gateway créée."
  value       = module.gateway.id
}

output "status" {
  description = "Statut courant de la gateway."
  value       = module.gateway.status
}

output "vip_address" {
  description = "VIP privée de la gateway dans le VNet."
  value       = module.gateway.vip_address
}

output "public_ip" {
  description = "IP publique attachée, ou `null`."
  value       = module.gateway.public_ip_address
}

output "hostnames" {
  description = "Liste des hostnames exposés (même ordre que l'input)."
  value       = var.hostnames
}

output "listener_ids" {
  description = "Map keyed par hostname → UUID listener."
  value       = { for h, l in ccp_appgw_listener.this : l.hostname => l.id }
}

output "target_group_ids" {
  description = "Map keyed par clé logique → UUID target group."
  value       = { for k, m in module.target_groups : k => m.id }
}

output "route_ids" {
  description = "Liste des UUID des routes, dans l'ordre déclaré."
  value       = [for r in module.routes : r.id]
}

output "url" {
  description = "URL canonique HTTPS (premier hostname)."
  value       = "https://${var.hostnames[0]}"
}

output "cache_effective_size_mb" {
  description = "Budget du cache en Mio."
  value       = module.gateway.cache_effective_size_mb
}

output "cache_size_limit_mb" {
  description = "Budget du cache en Mio."
  value       = module.gateway.cache_size_limit_mb
}

output "cache_size_mb" {
  description = "Budget de cache attribué par le plan, en Mio."
  value       = module.gateway.cache_size_mb
}

output "cache_max_object_kb" {
  description = "Taille maximale d'un objet attribuée par le plan, en Kio."
  value       = module.gateway.cache_max_object_kb
}

output "cache_enabled" {
  description = "Activation du cache HTTP de la passerelle."
  value       = module.gateway.cache_enabled
}
