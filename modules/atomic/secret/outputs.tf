output "id" {
  description = "UUID of the secret. Reference this from a CCPSecret CRD via spec.secretRef.name (with the secret's name)."
  value       = ccp_secret.this.id
}

output "name" {
  description = "DNS-friendly secret name — use this in the CCPSecret CRD's spec.secretRef.name."
  value       = ccp_secret.this.name
}

output "version" {
  description = "Monotonic version counter — bumps on every rotation. Compare against the CCPSecret status.syncedVersion to monitor sync."
  value       = ccp_secret.this.version
}

output "created_at" {
  description = "RFC 3339 creation timestamp."
  value       = ccp_secret.this.created_at
}

output "updated_at" {
  description = "RFC 3339 timestamp of the last metadata edit or rotation."
  value       = ccp_secret.this.updated_at
}
