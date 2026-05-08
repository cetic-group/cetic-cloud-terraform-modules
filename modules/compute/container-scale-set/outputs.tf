output "id" {
  description = "UUID du scale set."
  value       = ccp_container_scale_set.this.id
}

output "status" {
  value = ccp_container_scale_set.this.status
}
