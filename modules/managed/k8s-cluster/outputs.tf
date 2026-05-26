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

output "tier" {
  description = "Niveau de service effectif du cluster (`dev` ou `prod`)."
  value       = ccp_k8s_cluster.this.tier
}

output "proxy_secondary_vmid" {
  description = "VMID du frontal d'exposition secondaire (tier `prod`). `null` en tier `dev`."
  value       = ccp_k8s_cluster.this.proxy_secondary_vmid
}

output "proxy_secondary_node" {
  description = "Hôte Proxmox du frontal d'exposition secondaire (tier `prod`). `null` en tier `dev`."
  value       = ccp_k8s_cluster.this.proxy_secondary_node
}

output "proxy_vip_vnet" {
  description = "Adresse de la VIP flottante VNet partagée entre les deux frontaux (tier `prod`). `null` en tier `dev`."
  value       = ccp_k8s_cluster.this.proxy_vip_vnet
}
