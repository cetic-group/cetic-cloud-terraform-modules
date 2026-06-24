# Peer 2 VPCs — établir une relation de peering inter-VPC.
#
# Ordre canonique normalisé côté provider TF (vpc_a_id < vpc_b_id).
resource "ccp_vpc_peering" "this" {
  provider = ccp
  name     = var.name
  vpc_a_id = var.vpc_a_id
  vpc_b_id = var.vpc_b_id
  tags     = var.tags
}
