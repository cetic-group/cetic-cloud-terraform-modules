variable "name" {
  type        = string
  description = "Nom du peering (2-100 chars)."
  validation {
    condition     = length(var.name) >= 2 && length(var.name) <= 100
    error_message = "name doit faire 2-100 chars."
  }
}

variable "vnet_a_id" {
  type        = string
  description = "UUID d'un des deux VNets. L'ordre n'a pas d'importance — le provider normalise."
}

variable "vnet_b_id" {
  type        = string
  description = "UUID de l'autre VNet (différent de vnet_a_id, peut être dans un autre VPC)."
}

variable "tags" {
  type    = list(string)
  default = []
}
