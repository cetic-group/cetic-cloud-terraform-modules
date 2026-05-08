output "id" {
  description = "UUID du peering."
  value       = ccp_vnet_peering.this.id
}

output "status" {
  description = "Statut : `pending` / `active` / `deleting` / `error`."
  value       = ccp_vnet_peering.this.status
}
