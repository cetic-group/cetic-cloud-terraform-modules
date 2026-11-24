output "id" {
  description = "UUID du cluster."
  value       = ccp_k8s_cluster.this.id
}

output "name" {
  description = "Nom du cluster."
  value       = ccp_k8s_cluster.this.name
}

output "os_image" {
  description = "Famille d'OS effective des nodes du cluster (`flatcar` | `ubuntu` | `rocky9`)."
  value       = ccp_k8s_cluster.this.os_image
}

output "k8s_version" {
  description = "Version Kubernetes du plan de contrôle du cluster."
  value       = ccp_k8s_cluster.this.k8s_version
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

output "additional_pool_k8s_versions" {
  description = "Map keyed par nom de pool → version Kubernetes worker effective (héritée du control plane si non fixée)."
  value       = { for k, v in ccp_k8s_node_pool.additional : k => v.k8s_version }
}

output "additional_pool_disk_gb" {
  description = "Map keyed par nom de pool → taille de disque racine effective (GB, défaut du plan si non fixée)."
  value       = { for k, v in ccp_k8s_node_pool.additional : k => v.disk_gb }
}

output "status" {
  value = ccp_k8s_cluster.this.status
}

output "plan" {
  description = "Plan effectif du plan de contrôle (`starter`, `standard` ou `pro`)."
  value       = ccp_k8s_cluster.this.plan
}

output "etcd_volume_gb" {
  description = "Volume etcd effectif (GiB) : celui du plan à la création, relevé à la montée de plan, jamais réduit."
  value       = ccp_k8s_cluster.this.etcd_volume_gb
}

output "node_ip_block_size" {
  description = "Taille du bloc d'IP des nodes alloué dans le VNet (`null` tant qu'il n'est pas alloué)."
  value       = ccp_k8s_cluster.this.node_ip_block_size
}

output "current_k8s_version" {
  description = "Version Kubernetes réellement exécutée par le plan de contrôle (peut dépasser `k8s_version` après un patch automatique)."
  value       = ccp_k8s_cluster.this.current_k8s_version
}

output "tier" {
  description = "**Déprécié** — utiliser `plan`. Niveau de service effectif du cluster (`dev` pour `starter`, `prod` pour `standard`/`pro`)."
  # Dérivé de `plan` : lire l'attribut `tier` (déprécié) ferait afficher
  # l'avertissement de dépréciation du provider à chaque utilisateur du module.
  value = ccp_k8s_cluster.this.plan == null ? null : (ccp_k8s_cluster.this.plan == "starter" ? "dev" : "prod")
}

output "proxy_vip_vnet" {
  description = "Adresse de la VIP flottante VNet partagée entre les deux frontaux (plans `standard` et `pro`). `null` en plan `starter`."
  value       = ccp_k8s_cluster.this.proxy_vip_vnet
}
