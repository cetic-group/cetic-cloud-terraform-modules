locals {
  # Normalise le rattachement VPC : `vpc_ids` prioritaire, sinon `vpc_id` seul.
  vpc_ids = var.vpc_ids != null ? var.vpc_ids : (var.vpc_id != null ? [var.vpc_id] : [])
}

# ── 1. Passerelle d'accès VPN privé ───────────────────────────────────────────
resource "ccp_vpn_gateway" "this" {
  provider = ccp

  name           = var.name
  region         = var.region
  plan           = var.plan
  vpc_ids        = local.vpc_ids
  public_ip_id   = var.public_ip_id
  peer_pool_cidr = var.peer_pool_cidr
  dns            = var.dns
  tags           = var.tags

  lifecycle {
    precondition {
      condition     = length(local.vpc_ids) >= 1
      error_message = "Au moins un VPC doit être rattaché : fournissez `vpc_ids` (liste) ou `vpc_id` (unique)."
    }
  }
}

# ── 2. Clients VPN (peers) ─────────────────────────────────────────────────────
resource "ccp_vpn_peer" "this" {
  provider = ccp
  for_each = var.peers

  gateway_id        = ccp_vpn_gateway.this.id
  name              = coalesce(each.value.name, each.key)
  public_key        = each.value.public_key
  store_private_key = each.value.managed ? each.value.store_private_key : null
  one_time          = each.value.managed ? each.value.one_time : null
}
