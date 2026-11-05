output "id" {
  description = "UUID de l'Application Gateway."
  value       = ccp_application_gateway.this.id
}

output "name" {
  description = "Nom de l'AppGW."
  value       = ccp_application_gateway.this.name
}

output "status" {
  description = "Statut courant : `creating`, `active`, `error`, `deleting`."
  value       = ccp_application_gateway.this.status
}

output "vip_address" {
  description = "VIP privée flottante de la gateway (dans le VNet)."
  value       = ccp_application_gateway.this.vip_address
}

output "public_ip_address" {
  description = "IP publique attachée, ou `null` si gateway interne."
  value       = ccp_application_gateway.this.public_ip_address
}

output "plan" {
  description = "Plan effectif appliqué (`small` / `medium` / `large`)."
  value       = ccp_application_gateway.this.plan
}

output "region" {
  description = "Région de la gateway."
  value       = ccp_application_gateway.this.region
}

output "cache_effective_size_mb" {
  description = "Budget du cache en Mio."
  value       = ccp_application_gateway.this.cache_effective_size_mb
}

output "cache_size_limit_mb" {
  description = "Budget du cache en Mio."
  value       = ccp_application_gateway.this.cache_size_limit_mb
}

output "cache_size_mb" {
  description = "Budget de cache attribué par le plan, en Mio."
  value       = ccp_application_gateway.this.cache_size_mb
}

output "cache_max_object_kb" {
  description = "Taille maximale d'un objet attribuée par le plan, en Kio."
  value       = ccp_application_gateway.this.cache_max_object_kb
}

output "cache_enabled" {
  description = "Activation du cache HTTP de la passerelle."
  value       = ccp_application_gateway.this.cache_enabled
}

output "replica_count" {
  description = "Nombre d'instances provisionnées."
  value       = ccp_application_gateway.this.replica_count
}

output "l7_policy" {
  value       = ccp_application_gateway.this.l7_policy
  description = "État de politique lu sur la ressource (l7_policy)."
}

output "security_revision" {
  value       = ccp_application_gateway.this.security_revision
  description = "État de politique lu sur la ressource (security_revision)."
}

output "l4_policy" {
  value       = ccp_application_gateway.this.l4_policy
  description = "État de politique lu sur la ressource (l4_policy)."
}

output "client_ip_policy" {
  value       = ccp_application_gateway.this.client_ip_policy
  description = "État de politique lu sur la ressource (client_ip_policy)."
}

output "access_policy_state" {
  value       = ccp_application_gateway.this.access_policy_state
  description = "État de politique lu sur la ressource (access_policy_state)."
}
