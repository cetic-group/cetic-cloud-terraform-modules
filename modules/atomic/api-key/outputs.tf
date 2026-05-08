output "id" {
  description = "UUID de la clé API."
  value       = ccp_api_key.this.id
}

output "prefix" {
  description = "Préfixe visible de la clé (`ccp_live_xxxxxxxx`) — utile pour identifier dans les logs."
  value       = ccp_api_key.this.prefix
}

output "token" {
  description = "Token complet `ccp_live_…`. **Sensible** — visible une seule fois à la création, jamais ré-exposé après. Stocker dans un secret manager."
  value       = ccp_api_key.this.token
  sensitive   = true
}
