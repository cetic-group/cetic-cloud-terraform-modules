output "id" {
  description = "UUID du peering."
  value       = ccp_vpc_peering.this.id
}

output "status" {
  description = "Statut du peering."
  value       = ccp_vpc_peering.this.status
}
