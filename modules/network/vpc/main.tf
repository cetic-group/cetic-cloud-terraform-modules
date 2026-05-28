resource "ccp_vpc" "this" {
  provider = cetic-cloud-platform
  name     = var.name
  region   = var.region
  tags     = var.tags
}

resource "ccp_vnet" "this" {
  provider = cetic-cloud-platform
  for_each = var.vnets

  vpc_id   = ccp_vpc.this.id
  name     = coalesce(each.value.name, each.key)
  cidr     = each.value.cidr
  snat     = each.value.snat
  isolated = each.value.isolated
  tags     = each.value.tags
}

# ── IP reservations (par VNet) ────────────────────────────────────────────────
# Aplatit la map of map[reservations] en une seule map indexable par
# `<vnet_key>:<reservation_key>` pour for_each.
locals {
  ip_reservations_flat = merge([
    for vnet_key, vnet_cfg in var.vnets : {
      for resv_key, resv in vnet_cfg.ip_reservations :
      "${vnet_key}:${resv_key}" => merge(resv, {
        vnet_key = vnet_key
        name     = resv_key
      })
    }
  ]...)

  firewall_rules_flat = merge([
    for vnet_key, vnet_cfg in var.vnets : {
      for idx, rule in vnet_cfg.firewall_rules :
      "${vnet_key}:${idx}" => merge(rule, {
        vnet_key = vnet_key
        position = (idx + 1) * 10 # 10, 20, 30 — laisse de la marge pour insertions manuelles
      })
    }
  ]...)
}

resource "ccp_vnet_ip_reservation" "this" {
  provider = cetic-cloud-platform
  for_each = local.ip_reservations_flat

  vnet_id     = ccp_vnet.this[each.value.vnet_key].id
  name        = each.value.name
  ip          = each.value.ip
  range_end   = each.value.range_end
  description = each.value.description
}

resource "ccp_vnet_firewall_rule" "this" {
  provider = cetic-cloud-platform
  for_each = local.firewall_rules_flat

  vnet_id     = ccp_vnet.this[each.value.vnet_key].id
  direction   = lower(each.value.direction)
  action      = "ACCEPT"
  proto       = each.value.protocol
  source_cidr = each.value.source_cidr
  dest_cidr   = each.value.dest_cidr
  dport       = each.value.port
  enabled     = true
  position    = each.value.position
  comment     = each.value.description
}

## Peering : a été retiré du module en v0.3.0 (provider v0.9.0 a supprimé
## ccp_vpc_peering, l'endpoint backend n'a jamais existé). Pour peer ce
## VPC avec d'autres, utiliser `modules/network/vnet-peering` couple par
## couple — le backend accepte les peerings intra-VPC ET inter-VPC.
