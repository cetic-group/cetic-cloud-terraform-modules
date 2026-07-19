locals {
  public_url = (
    var.exposure_type == "appgw"
    ? "https://${local.appgw_hostname_effective}"
    : "http://${ccp_public_ip.exposure.ip_address}"
  )
}

output "public_url" {
  description = "URL publique de l'app. HTTPS si `exposure_type=\"appgw\"`, HTTP via IP sinon."
  value       = local.public_url
}

output "public_ip" {
  description = "IP publique attachée (LB ou AppGW selon `exposure_type`)."
  value       = ccp_public_ip.exposure.ip_address
}

output "exposure_type" {
  description = "Mode d'exposition retenu : `lb` ou `appgw`."
  value       = var.exposure_type
}

# ── LB outputs (null si exposure_type=appgw) ─────────────────────────────────
output "lb_id" {
  description = "UUID du load balancer. `null` si `exposure_type=\"appgw\"`."
  value       = var.exposure_type == "lb" ? ccp_load_balancer.this[0].id : null
}

output "lb_vip_address" {
  description = "VIP privée du load balancer dans le VNet web. `null` si `exposure_type=\"appgw\"`."
  value       = var.exposure_type == "lb" ? ccp_load_balancer.this[0].vip_address : null
}

# ── AppGW outputs (null si exposure_type=lb) ─────────────────────────────────
output "appgw_id" {
  description = "UUID de l'Application Gateway. `null` si `exposure_type=\"lb\"`."
  value       = var.exposure_type == "appgw" ? module.appgw[0].appgw_id : null
}

output "appgw_hostname" {
  description = "Hostname effectif de l'AppGW. `null` si `exposure_type=\"lb\"`."
  value       = var.exposure_type == "appgw" ? local.appgw_hostname_effective : null
}

output "appgw_vip_address" {
  description = "VIP privée de l'AppGW dans le VNet web. `null` si `exposure_type=\"lb\"`."
  value       = var.exposure_type == "appgw" ? module.appgw[0].vip_address : null
}

# ── Communs ──────────────────────────────────────────────────────────────────
output "vpc_id" {
  description = "UUID du VPC créé."
  value       = module.vpc.vpc_id
}

output "container_ids" {
  description = "Map keyed par nom d'instance → UUID du container app."
  value       = { for k, v in ccp_container_instance.app : k => v.id }
}

output "ssh_key_id" {
  description = "UUID de la clé SSH ops (utilisable pour d'autres ressources)."
  value       = module.ssh_key.id
}

output "schedule_ids" {
  description = "Map keyed par nom d'instance → UUID du planning marche/arrêt. Vide si `schedule_windows` non fourni."
  value       = { for k, m in module.app_schedule : k => m.id }
}

output "schedule_estimated_monthly_fee_cents" {
  description = "Somme des frais mensuels estimés du scheduler (centimes) sur tous les containers pilotés. `0` si aucun planning."
  value       = sum(concat([0], [for m in module.app_schedule : m.estimated_monthly_fee_cents]))
}

output "database_endpoint" {
  description = "Endpoint PostgreSQL `host:port` (IP privée du VNet data). `null` si DB désactivée."
  value       = var.enable_database ? "${ccp_db_pg_instance.app_db[0].endpoint_vnet_ip}:${ccp_db_pg_instance.app_db[0].endpoint_port}" : null
}

output "database_admin_username" {
  description = "Username admin PostgreSQL. `null` si DB désactivée."
  value       = var.enable_database ? ccp_db_pg_instance.app_db[0].admin_username : null
}

output "database_admin_database" {
  description = "Nom de la database admin PG. `null` si DB désactivée."
  value       = var.enable_database ? ccp_db_pg_instance.app_db[0].admin_database : null
}

output "database_id" {
  description = "UUID de l'instance PostgreSQL. Utilise-le avec `cetic db pg credentials <id>` pour récupérer le password (non exposé en TF par sécurité)."
  value       = var.enable_database ? ccp_db_pg_instance.app_db[0].id : null
}

output "database_tier" {
  description = "Tier PostgreSQL (`dev` / `prod`) calculé automatiquement à partir de `db_replicas`."
  value       = var.enable_database ? ccp_db_pg_instance.app_db[0].tier : null
}
