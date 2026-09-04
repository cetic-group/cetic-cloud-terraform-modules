output "id" {
  description = "UUID de la zone."
  value       = ccp_dns_zone.this.id
}

output "name" {
  description = "Nom de la zone, normalisé en minuscules par la plateforme."
  value       = ccp_dns_zone.this.name
}

output "status" {
  description = "`pending_verification`, `provisioning`, `active` ou `error`. `error` est terminal : supprimer la zone et la redéclarer."
  value       = ccp_dns_zone.this.status
}

output "resolver_addresses" {
  description = <<-EOT
    Adresses à donner comme serveur de noms — **une par sous-réseau servi**.
    Vide tant que le serveur n'est pas debout.
  EOT
  value       = ccp_dns_zone.this.resolver_addresses
}

output "resolver_endpoints" {
  description = "Les mêmes adresses, chacune avec le sous-réseau qu'elle dessert (`address`, `vnet_id`, `vnet_name`, `vnet_cidr`)."
  value       = ccp_dns_zone.this.resolver_endpoints
}

output "resolver_by_vnet" {
  description = <<-EOT
    Sous-réseau (UUID) → adresse du serveur de noms à y utiliser.

    C'est la forme à consommer : depuis une machine, il faut l'adresse de SON
    sous-réseau. Elles répondent toutes les mêmes zones, mais chacune n'est
    joignable que depuis le sien — une adresse prise dans le mauvais réseau ne
    répond pas, et la panne se lit comme une panne du service DNS.
  EOT
  value       = { for e in ccp_dns_zone.this.resolver_endpoints : e.vnet_id => e.address }
}

output "resolver_tier" {
  description = <<-EOT
    Niveau réellement en service sur le réseau.

    ⚠️ Tant que la zone attend sa preuve de possession, c'est le niveau
    **demandé** qui est rendu : aucun serveur n'est encore debout.
  EOT
  value       = ccp_dns_zone.this.resolver_tier
}

output "resolver_status" {
  description = "État du serveur de noms lui-même : `provisioning`, `active` ou `error`. Constaté, jamais déduit de l'état de la zone."
  value       = ccp_dns_zone.this.resolver_status
}

output "ns_hostname" {
  description = "Nom du serveur publié à l'apex de la zone. Informatif : il ne résout que par ce serveur-là."
  value       = ccp_dns_zone.this.ns_hostname
}

output "ownership_challenge" {
  description = <<-EOT
    Pour un domaine public en attente : l'enregistrement à publier dans son DNS
    **public** (`record_name`, `record_type`, `record_value`). `null` sur un
    suffixe interne, et `null` une fois la preuve acceptée.
  EOT
  value       = ccp_dns_zone.this.ownership_challenge
}

output "record_ids" {
  description = "Clé de `records` → UUID de l'enregistrement créé."
  value       = { for k, r in ccp_dns_record.this : k => r.id }
}

output "record_fqdns" {
  description = "Clé de `records` → nom pleinement qualifié tel que la plateforme le stocke."
  value       = { for k, r in ccp_dns_record.this : k => r.fqdn }
}
