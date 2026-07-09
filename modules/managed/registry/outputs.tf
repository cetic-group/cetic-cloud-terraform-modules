output "id" {
  description = "UUID of the registry."
  value       = ccp_registry.this.id
}

output "name" {
  description = "Human-readable name."
  value       = ccp_registry.this.name
}

output "slug" {
  description = "URL-safe slug derived from name."
  value       = ccp_registry.this.slug
}

output "region" {
  description = "Region code."
  value       = ccp_registry.this.region
}

output "url" {
  description = "Full HTTPS URL — same value reached over Internet or LAN (DNS split-horizon)."
  value       = ccp_registry.this.url
}

output "expose_public" {
  description = "Whether the registry is exposed on the public Internet."
  value       = ccp_registry.this.expose_public
}

output "expose_private" {
  description = "Whether the registry is exposed on the CETIC private LAN."
  value       = ccp_registry.this.expose_private
}

output "status" {
  description = "Provisioning status."
  value       = ccp_registry.this.status
}

output "admin_username" {
  description = "Admin username (typically `admin`)."
  value       = ccp_registry.this.admin_username
}

output "admin_password" {
  description = "One-shot admin password — written to state at creation."
  value       = ccp_registry.this.admin_password
  sensitive   = true
}

output "storage_gb" {
  description = "Effective storage quota (gigabytes). Platform default when `storage_gb` is omitted."
  value       = ccp_registry.this.storage_gb
}

output "storage_used_gb" {
  description = "Approximate storage used by registry blobs (gigabytes)."
  value       = ccp_registry.this.storage_used_gb
}

output "last_push_at" {
  description = "RFC 3339 timestamp of the last push observed."
  value       = ccp_registry.this.last_push_at
}
