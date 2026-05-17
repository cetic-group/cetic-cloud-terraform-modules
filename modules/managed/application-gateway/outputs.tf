output "id" {
  description = "UUID de l'Application Gateway."
  value       = module.gateway.id
}

output "status" {
  description = "Statut courant : `creating` / `active` / `error` / `deleting`."
  value       = module.gateway.status
}

output "plan" {
  description = "Plan effectif appliqué."
  value       = module.gateway.plan
}

output "region" {
  description = "Région de la gateway."
  value       = module.gateway.region
}

output "vip_address" {
  description = "VIP privée flottante de la gateway dans le VNet."
  value       = module.gateway.vip_address
}

output "public_ip_address" {
  description = "IP publique attachée à la gateway, ou `null` si AppGW interne."
  value       = module.gateway.public_ip_address
}

output "hostnames" {
  description = "Liste des hostnames exposés, dans l'ordre d'input."
  value       = var.hostnames
}

output "listener_ids" {
  description = "Map keyed par hostname → UUID listener."
  value       = { for k, m in module.listeners : m.hostname => m.id }
}

output "listener_acme_status" {
  description = "Map keyed par hostname → statut ACME (`pending` / `issued` / `failed`)."
  value       = { for k, m in module.listeners : m.hostname => m.acme_status }
}

output "target_group_ids" {
  description = "Map keyed par clé logique → UUID target group."
  value       = { for k, m in module.target_groups : k => m.id }
}

output "target_group_member_ids" {
  description = "Map keyed par target_group_key → map(label → member UUID)."
  value       = { for k, m in module.target_groups : k => m.member_ids }
}

output "route_ids" {
  description = "Liste des UUID des routes, dans l'ordre déclaré."
  value       = [for r in module.routes : r.id]
}

output "route_basic_auth_secret_refs" {
  description = <<-EOT
    Liste des références opaques Secret Manager backing les credentials basic auth de chaque route
    (`null` pour les routes sans auth), dans l'ordre déclaré. Sensitive (propage la marque du
    sub-module appgw-route qui suit le provider — Terraform refuse l'output non-sensitive sinon).
  EOT
  value       = [for r in module.routes : r.basic_auth_secret_ref]
  sensitive   = true
}

output "url" {
  description = "URL canonique HTTPS (premier hostname). Pratique pour un `terraform output url`."
  value       = "https://${var.hostnames[0]}"
}
