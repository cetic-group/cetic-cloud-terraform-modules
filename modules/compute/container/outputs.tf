output "id" {
  description = "UUID du container."
  value       = ccp_container_instance.this.id
}

output "ip_address" {
  description = "IP privée du container dans son VNet."
  value       = ccp_container_instance.this.ip_address
}

output "public_ip_address" {
  description = "IP publique attachée, ou `null`."
  value       = ccp_container_instance.this.public_ip_address
}

output "status" {
  description = "Statut courant."
  value       = ccp_container_instance.this.status
}

output "cores" {
  description = "Nombre de vCPU effectifs."
  value       = ccp_container_instance.this.cores
}

output "memory_mb" {
  description = "RAM effective (MB)."
  value       = ccp_container_instance.this.memory_mb
}

output "disk_gb" {
  description = "Disque effectif (GB)."
  value       = ccp_container_instance.this.disk_gb
}
