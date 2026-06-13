output "id" {
  description = "UUID du bastion."
  value       = ccp_bastion.this.id
}

output "status" {
  description = "Statut courant : `provisioning` / `active` / `error` / `deleting`."
  value       = ccp_bastion.this.status
}

output "endpoint_host" {
  description = "Hôte public du point d'entrée SSH (FQDN ou IP) auquel se connectent les opérateurs."
  value       = ccp_bastion.this.endpoint_host
}

output "endpoint_port" {
  description = "Port TCP du point d'entrée SSH."
  value       = ccp_bastion.this.endpoint_port
}

output "public_ip_address" {
  description = "IP publique attachée au point d'entrée du bastion."
  value       = ccp_bastion.this.public_ip_address
}

output "vpc_ids" {
  description = "Ensemble des UUID de VPC fronté(s) par le bastion (le VPC primaire est toujours inclus)."
  value       = ccp_bastion.this.vpc_ids
}
