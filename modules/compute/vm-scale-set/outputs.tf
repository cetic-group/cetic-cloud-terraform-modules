output "id" {
  description = "UUID du scale set."
  value       = ccp_vm_scale_set.this.id
}

output "status" {
  value = ccp_vm_scale_set.this.status
}

output "os_family" {
  description = "Famille d'OS dérivée du template (linux | windows)."
  value       = ccp_vm_scale_set.this.os_family
}

output "disk_gb" {
  description = "Disque racine effectif (GB), appliqué à chaque réplica."
  value       = ccp_vm_scale_set.this.disk_gb
}
