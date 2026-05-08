output "vpc_id" {
  description = "UUID du VPC."
  value       = ccp_vpc.this.id
}

output "vpc" {
  description = "Objet VPC complet (id, name, region, status, tags, vlan_id, sdn_type)."
  value = {
    id       = ccp_vpc.this.id
    name     = ccp_vpc.this.name
    region   = ccp_vpc.this.region
    status   = ccp_vpc.this.status
    tags     = ccp_vpc.this.tags
    vlan_id  = ccp_vpc.this.vlan_id
    sdn_type = ccp_vpc.this.sdn_type
  }
}

output "vnet_ids" {
  description = "Map keyed par nom logique → UUID du VNet (à passer à d'autres modules)."
  value       = { for k, v in ccp_vnet.this : k => v.id }
}

output "vnets" {
  description = "Map keyed par nom logique → objet VNet complet (id, name, cidr, gateway, dhcp_start, dhcp_end, isolated, status)."
  value = {
    for k, v in ccp_vnet.this : k => {
      id         = v.id
      name       = v.name
      cidr       = v.cidr
      gateway    = v.gateway
      dhcp_start = v.dhcp_start
      dhcp_end   = v.dhcp_end
      isolated   = v.isolated
      status     = v.status
    }
  }
}

output "ip_reservations" {
  description = "Map keyed par `<vnet_key>:<reservation_key>` → { id, ip, range_end, ip_count, kind }."
  value = {
    for k, v in ccp_vnet_ip_reservation.this : k => {
      id        = v.id
      ip        = v.ip
      range_end = v.range_end
      ip_count  = v.ip_count
      kind      = v.kind
    }
  }
}

# `peering_ids` retiré en v0.3.0 — voir `modules/network/vnet-peering`.
