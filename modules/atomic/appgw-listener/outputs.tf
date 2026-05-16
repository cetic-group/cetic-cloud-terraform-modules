output "id" {
  description = "UUID du listener."
  value       = ccp_appgw_listener.this.id
}

output "appgw_id" {
  description = "UUID de la gateway parente."
  value       = ccp_appgw_listener.this.appgw_id
}

output "hostname" {
  description = "Hostname effectivement servi."
  value       = ccp_appgw_listener.this.hostname
}

output "custom_domain" {
  description = "`true` si le hostname est un domaine client (ACME DNS-01)."
  value       = ccp_appgw_listener.this.custom_domain
}

output "acme_status" {
  description = "État d'émission du certificat ACME : `pending` / `issued` / `failed`."
  value       = ccp_appgw_listener.this.acme_status
}

output "acme_last_renewal_at" {
  description = "Timestamp RFC 3339 de la dernière émission/renouvellement réussi (ou `null`)."
  value       = ccp_appgw_listener.this.acme_last_renewal_at
}

output "cert_path" {
  description = "Chemin filesystem côté gateway du certificat live (informatif)."
  value       = ccp_appgw_listener.this.cert_path
}

output "created_at" {
  description = "Timestamp RFC 3339 de création du listener."
  value       = ccp_appgw_listener.this.created_at
}
