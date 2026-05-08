output "id" {
  description = "UUID de l'instance PostgreSQL."
  value       = ccp_db_pg_instance.this.id
}

output "tier" {
  description = "Tier dérivé : `dev` (replicas=1) ou `prod` (replicas=3)."
  value       = ccp_db_pg_instance.this.tier
}

output "endpoint_host" {
  description = "IP privée du endpoint dans le VNet."
  value       = ccp_db_pg_instance.this.endpoint_vnet_ip
}

output "endpoint_port" {
  description = "Port d'écoute (5432 par défaut)."
  value       = ccp_db_pg_instance.this.endpoint_port
}

output "endpoint" {
  description = "Endpoint formaté `host:port`."
  value       = "${ccp_db_pg_instance.this.endpoint_vnet_ip}:${ccp_db_pg_instance.this.endpoint_port}"
}

output "admin_username" {
  value = ccp_db_pg_instance.this.admin_username
}

output "admin_database" {
  value = ccp_db_pg_instance.this.admin_database
}

output "status" {
  value = ccp_db_pg_instance.this.status
}
