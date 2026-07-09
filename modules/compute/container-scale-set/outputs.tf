output "id" {
  description = "UUID du scale set."
  value       = ccp_container_scale_set.this.id
}

output "status" {
  value = ccp_container_scale_set.this.status
}

output "disk_gb" {
  description = "Disque racine effectif (GB), appliqué à chaque réplica."
  value       = ccp_container_scale_set.this.disk_gb
}
