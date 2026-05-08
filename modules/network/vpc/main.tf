resource "ccp_vpc" "this" {
  name   = var.name
  region = var.region
  tags   = var.tags
}

resource "ccp_vnet" "this" {
  for_each = var.vnets

  vpc_id = ccp_vpc.this.id
  name   = coalesce(each.value.name, each.key)
  cidr   = each.value.cidr
  snat   = each.value.snat
  tags   = each.value.tags
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
  for_each = local.ip_reservations_flat

  vnet_id     = ccp_vnet.this[each.value.vnet_key].id
  name        = each.value.name
  ip          = each.value.ip
  range_end   = each.value.range_end
  description = each.value.description
}

resource "ccp_vnet_firewall_rule" "this" {
  for_each = local.firewall_rules_flat

  vnet_id     = ccp_vnet.this[each.value.vnet_key].id
  direction   = upper(each.value.direction)
  action      = "ACCEPT"
  proto       = each.value.protocol
  source_cidr = each.value.source_cidr
  dest_cidr   = each.value.dest_cidr
  dport       = each.value.port
  enabled     = true
  position    = each.value.position
  comment     = each.value.description
}

resource "ccp_vpc_peering" "this" {
  for_each = toset(var.peering_accepter_vpc_ids)

  requester_vpc_id = ccp_vpc.this.id
  accepter_vpc_id  = each.value
}
