variable "requester_vpc_id" {
  type        = string
  description = "UUID du VPC demandeur."
}

variable "accepter_vpc_id" {
  type        = string
  description = "UUID du VPC acceptant. Doit être dans la même région que `requester_vpc_id`. CIDRs ne doivent pas se chevaucher."
}
