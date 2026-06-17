output "id" {
  description = "UUID de la VM."
  value       = ccp_vm_instance.this.id
}

output "ip_address" {
  description = "IP privée."
  value       = ccp_vm_instance.this.ip_address
}

output "public_ip_address" {
  description = "IP publique attachée, ou `null`."
  value       = ccp_vm_instance.this.public_ip_address
}

output "status" {
  value = ccp_vm_instance.this.status
}

output "os_family" {
  description = "Famille d'OS dérivée du template (linux | windows)."
  value       = ccp_vm_instance.this.os_family
}

output "cores" {
  value = ccp_vm_instance.this.cores
}

output "memory_mb" {
  value = ccp_vm_instance.this.memory_mb
}

output "disk_gb" {
  value = ccp_vm_instance.this.disk_gb
}
