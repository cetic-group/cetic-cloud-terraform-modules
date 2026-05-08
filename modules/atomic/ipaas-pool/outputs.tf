output "id" {
  description = "UUID du pool IPaaS."
  value       = ccp_ipaas_pool.this.id
}

output "kind" {
  description = "Type du pool (`ipaas_routed`)."
  value       = ccp_ipaas_pool.this.kind
}

output "edge_id" {
  description = "UUID de l'edge associé."
  value       = ccp_ipaas_pool.this.edge_id
}
