output "url" {
  description = "URL publique HTTPS de l'app (le hostname client servi par l'AppGW)."
  value       = "https://${var.hostname}"
}

output "public_ip" {
  description = "IP publique attachée à l'AppGW (exposée pour debug/audit). Ne pas CNAMER `hostname` directement vers cette IP — utiliser le sous-domaine `app.cloud.cetic-group.com` de la gateway comme cible CNAME (ACME DNS-01 ne valide que via le CNAME, pas l'IP)."
  value       = module.public_ip.ip_address
}

output "hostname" {
  description = "Hostname client effectivement exposé."
  value       = var.hostname
}

output "appgw_id" {
  description = "UUID de l'Application Gateway."
  value       = module.appgw.id
}

output "appgw_vip_address" {
  description = "VIP privée de l'AppGW dans le VNet web."
  value       = module.appgw.vip_address
}

output "appgw_acme_status" {
  description = "Statut ACME du listener (`pending` au moment de la création, puis `issued` ~30-90s après si le CNAME DNS-01 est en place)."
  value       = module.appgw.listener_acme_status[var.hostname]
}

output "vpc_id" {
  description = "UUID du VPC."
  value       = module.vpc.vpc_id
}

output "container_id" {
  description = "UUID du container backend."
  value       = ccp_container_instance.app.id
}

output "basic_auth_secret_ref" {
  description = "Référence opaque Secret Manager backing les credentials basic auth (`null` si pas d'auth). Sensitive (propage la marque du module appgw — Terraform refuse l'output non-sensitive sinon)."
  value       = module.appgw.route_basic_auth_secret_refs[0]
  sensitive   = true
}

output "ssh_key_id" {
  description = "UUID de la clé SSH ops."
  value       = module.ssh_key.id
}
