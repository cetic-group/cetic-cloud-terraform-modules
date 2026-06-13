output "id" {
  description = "UUID de l'instance Windows."
  value       = ccp_windows_instance.this.id
}

output "hostname" {
  description = "Nom d'hôte (FQDN)."
  value       = ccp_windows_instance.this.hostname
}

output "ip_address" {
  description = "IP privée."
  value       = ccp_windows_instance.this.ip_address
}

output "public_ip_address" {
  description = "IP publique attachée, ou `null`."
  value       = ccp_windows_instance.this.public_ip_address
}

output "status" {
  description = "État : provisioning|active|stopped|error."
  value       = ccp_windows_instance.this.status
}

output "cores" {
  description = "Nombre de vCPU."
  value       = ccp_windows_instance.this.cores
}

output "memory_mb" {
  description = "Mémoire vive (MB)."
  value       = ccp_windows_instance.this.memory_mb
}

output "disk_gb" {
  description = "Taille disque système (GB)."
  value       = ccp_windows_instance.this.disk_gb
}
