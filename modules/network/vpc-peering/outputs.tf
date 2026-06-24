output "id" {
  description = "UUID du peering inter-VPC."
  value       = ccp_vpc_peering.this.id
}

output "status" {
  description = "Statut : `pending` / `active` / `deleting` / `error`."
  value       = ccp_vpc_peering.this.status
}
