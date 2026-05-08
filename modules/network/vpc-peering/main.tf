resource "ccp_vpc_peering" "this" {
  requester_vpc_id = var.requester_vpc_id
  accepter_vpc_id  = var.accepter_vpc_id
}
