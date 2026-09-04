# Zone DNS privée — servie UNIQUEMENT dans le réseau privé du client.
#
# Le serveur de noms n'est pas une ressource : il naît avec la PREMIÈRE zone du
# réseau et est démonté avec la DERNIÈRE. Il n'y a donc rien à créer ni à
# détruire séparément — et rien à déclarer ici pour l'obtenir.
#
# ⚠️ Les machines reçoivent ce serveur de noms **à leur création**. Poser une
# zone sur un réseau déjà peuplé ne la rend pas visible depuis les machines
# existantes : déclarer la zone AVANT les machines est l'ordre qui marche.
resource "ccp_dns_zone" "this" {
  provider = ccp

  name   = var.name
  vpc_id = var.vpc_id

  # `null` = on laisse le défaut de la plateforme. Poser une valeur en dur ici
  # rendrait ce réglage mort : un exploitant qui le change ne verrait jamais
  # d'effet, puisque le module enverrait toujours le sien.
  tier        = var.tier
  default_ttl = var.default_ttl

  dnssec_enabled        = var.dnssec_enabled
  wait_for_verification = var.wait_for_verification
}

# Un enregistrement = un couple (nom, type) et TOUTES ses valeurs. `records`
# remplace l'ensemble à chaque écriture — il n'y a pas d'ajout incrémental.
resource "ccp_dns_record" "this" {
  provider = ccp
  for_each = var.records

  zone_id = ccp_dns_zone.this.id
  name    = each.value.name
  type    = each.value.type
  records = each.value.records
  ttl     = each.value.ttl
}
