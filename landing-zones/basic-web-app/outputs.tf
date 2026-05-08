output "public_url" {
  description = "URL publique de l'app, basée sur l'IP du load balancer."
  value       = "http://${ccp_public_ip.lb.ip_address}"
}

output "public_ip" {
  description = "IP publique attachée au load balancer."
  value       = ccp_public_ip.lb.ip_address
}

output "lb_id" {
  description = "UUID du load balancer."
  value       = ccp_load_balancer.this.id
}

output "lb_vip_address" {
  description = "VIP privée du load balancer (dans le VNet web)."
  value       = ccp_load_balancer.this.vip_address
}

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
