output "id" {
  description = "UUID du scale set."
  value       = ccp_vm_scale_set.this.id
}

output "status" {
  value = ccp_vm_scale_set.this.status
}
