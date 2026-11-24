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

output "cluster_plan" {
  description = "Plan effectif du plan de contrôle (`starter`, `standard` ou `pro`)."
  value       = module.k8s.plan
}

output "cluster_current_k8s_version" {
  description = "Version Kubernetes réellement exécutée par le plan de contrôle."
  value       = module.k8s.current_k8s_version
}

output "cluster_etcd_volume_gb" {
  description = "Volume etcd effectif du cluster (GiB)."
  value       = module.k8s.etcd_volume_gb
}

output "cluster_node_ip_block_size" {
  description = "Taille du bloc d'IP des nodes alloué dans le VNet."
  value       = module.k8s.node_ip_block_size
}

output "cluster_tier" {
  description = "**Déprécié** — utiliser `cluster_plan`. Niveau de service effectif (`dev` ou `prod`)."
  value       = module.k8s.tier
}

output "cluster_os_image" {
  description = "Famille d'OS effective des nodes (`flatcar` | `ubuntu` | `rocky9`)."
  value       = module.k8s.os_image
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
