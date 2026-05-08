output "id" {
  description = "UUID du cluster."
  value       = ccp_k8s_cluster.this.id
}

output "name" {
  description = "Nom du cluster."
  value       = ccp_k8s_cluster.this.name
}

output "api_endpoint" {
  description = "Endpoint apiserver (host:port). Privé par défaut, public si `apiserver_public_ip_id` est fourni."
  value       = ccp_k8s_cluster.this.api_endpoint
}

output "apiserver_internal_ip" {
  description = "IP privée de l'apiserver."
  value       = ccp_k8s_cluster.this.apiserver_internal_ip
}

output "apiserver_public_ip_address" {
  description = "IP publique de l'apiserver, ou `null`."
  value       = ccp_k8s_cluster.this.public_ip_address
}

output "ingress_internal_ip" {
  description = "IP privée du controller ingress."
  value       = ccp_k8s_cluster.this.ingress_internal_ip
}

output "ingress_public_ip_address" {
  description = "IP publique du controller ingress, ou `null`."
  value       = ccp_k8s_cluster.this.ingress_public_ip_address
}

output "additional_pool_ids" {
  description = "Map keyed par nom de pool → UUID."
  value       = { for k, v in ccp_k8s_node_pool.additional : k => v.id }
}

output "status" {
  value = ccp_k8s_cluster.this.status
}
