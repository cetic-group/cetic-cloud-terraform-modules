# Peer 2 VNets — intra-VPC ou inter-VPC, peu importe (le backend accepte
# n'importe quel couple de VNets du même tenant).
#
# Ordre canonique normalisé côté provider TF (vnet_a_id < vnet_b_id).
resource "ccp_vnet_peering" "this" {
  name      = var.name
  vnet_a_id = var.vnet_a_id
  vnet_b_id = var.vnet_b_id
  tags      = var.tags
}
