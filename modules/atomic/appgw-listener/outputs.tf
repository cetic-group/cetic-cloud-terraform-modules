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

output "acme_challenge" {
  description = "Type de challenge ACME utilisé (`http01` / `dns01`), ou `null` si aucun cert."
  value       = ccp_appgw_listener.this.acme_challenge
}

output "acme_status" {
  description = "État d'émission du certificat ACME : `pending` / `issued` / `failed`."
  value       = ccp_appgw_listener.this.acme_status
}

output "acme_issued_at" {
  description = "Timestamp RFC 3339 d'émission du certificat courant (ou `null`)."
  value       = ccp_appgw_listener.this.acme_issued_at
}

output "acme_renew_after" {
  description = "Timestamp RFC 3339 après lequel le certificat est éligible au renouvellement (ou `null`)."
  value       = ccp_appgw_listener.this.acme_renew_after
}

output "acme_last_renewal_at" {
  description = "Timestamp RFC 3339 du dernier renouvellement réussi (ou `null`)."
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
