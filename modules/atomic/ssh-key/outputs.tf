output "id" {
  description = "UUID de la clé SSH (à passer dans `ssh_key_ids` des containers et VMs)."
  value       = ccp_ssh_key.this.id
}

output "name" {
  description = "Nom de la clé SSH."
  value       = ccp_ssh_key.this.name
}

output "fingerprint" {
  description = "Fingerprint SHA-256 de la clé publique (calculé côté CETIC Cloud)."
  value       = ccp_ssh_key.this.fingerprint
}
