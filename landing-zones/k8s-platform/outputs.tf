output "cluster_id" {
  description = "UUID du cluster K8s."
  value       = module.k8s.id
}

output "cluster_name" {
  description = "Nom du cluster."
  value       = module.k8s.name
}

output "api_endpoint" {
  description = "Endpoint apiserver. Récupérer le kubeconfig via `cetic k8s kubeconfig <id>`."
  value       = module.k8s.api_endpoint
}

output "apiserver_public_ip_address" {
  description = "IP publique apiserver, ou `null` si `expose_apiserver_publicly = false`."
  value       = module.k8s.apiserver_public_ip_address
}

output "ingress_public_ip_address" {
  description = "IP publique du controller ingress (si `ingress_scope = external`)."
  value       = module.k8s.ingress_public_ip_address
}

output "ingress_internal_ip" {
  description = "IP privée du controller ingress."
  value       = module.k8s.ingress_internal_ip
}

output "cluster_tier" {
  description = "Niveau de service effectif du cluster (`dev` ou `prod`)."
  value       = module.k8s.tier
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "database_endpoint" {
  description = "Endpoint PostgreSQL `host:port`. `null` si DB désactivée."
  value       = var.enable_database ? module.database[0].endpoint : null
}

output "database_id" {
  description = "UUID de l'instance PostgreSQL — utiliser avec le datasource `ccp_db_pg_credentials` pour récupérer le password."
  value       = var.enable_database ? module.database[0].id : null
}
