output "gateway_id" {
  description = "UUID de la passerelle VPN."
  value       = ccp_vpn_gateway.this.id
}

output "status" {
  description = "Statut courant : `creating` / `active` / `error` / `deleting`."
  value       = ccp_vpn_gateway.this.status
}

output "endpoint_host" {
  description = "Hôte public du point d'entrée VPN (FQDN ou IP) à utiliser côté client."
  value       = ccp_vpn_gateway.this.endpoint_host
}

output "endpoint_port" {
  description = "Port UDP du point d'entrée VPN."
  value       = ccp_vpn_gateway.this.endpoint_port
}

output "public_key" {
  description = "Clé publique de la passerelle, à renseigner dans la configuration de chaque client."
  value       = ccp_vpn_gateway.this.public_key
}

output "public_ip_address" {
  description = "IP publique du point d'entrée VPN."
  value       = ccp_vpn_gateway.this.public_ip_address
}

output "peers" {
  description = "Map keyed par label de peer → { id, ip } (adresse privée assignée au client)."
  value = {
    for k, p in ccp_vpn_peer.this : k => {
      id = p.id
      ip = p.ip
    }
  }
}

output "peer_configs" {
  description = <<-EOT
    Map keyed par label de peer → configuration cliente complète.
    Renseignée uniquement pour les peers en modèle « clé générée par la plateforme »
    (`null` pour les peers en modèle « clé fournie par le client »).
    Sensible — stockée dans le state Terraform.
  EOT
  value       = { for k, p in ccp_vpn_peer.this : k => p.config }
  sensitive   = true
}
