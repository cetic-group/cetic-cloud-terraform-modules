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
