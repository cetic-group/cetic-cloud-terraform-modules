output "id" {
  description = "UUID de l'instance Valkey."
  value       = ccp_db_valkey_instance.this.id
}

output "tier" {
  description = "Tier dérivé : `dev` (replicas=1) ou `prod` (replicas=3)."
  value       = ccp_db_valkey_instance.this.tier
}

output "endpoint_host" {
  description = "IP privée du endpoint dans le VNet."
  value       = ccp_db_valkey_instance.this.endpoint_vnet_ip
}

output "endpoint_port" {
  description = "Port d'écoute (6379 par défaut (Valkey/Redis))."
  value       = ccp_db_valkey_instance.this.endpoint_port
}

output "endpoint" {
  description = "Endpoint formaté `host:port`."
  value       = "${ccp_db_valkey_instance.this.endpoint_vnet_ip}:${ccp_db_valkey_instance.this.endpoint_port}"
}

output "cpu_millicores" {
  description = "CPU effectif (millicores) attribué à chaque replica."
  value       = ccp_db_valkey_instance.this.cpu_millicores
}

output "memory_mb" {
  description = "RAM effective (MB) par replica."
  value       = ccp_db_valkey_instance.this.memory_mb
}

output "status" {
  value = ccp_db_valkey_instance.this.status
}
