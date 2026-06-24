variable "name" {
  type        = string
  description = "Nom du peering inter-VPC (2-100 chars)."
  validation {
    condition     = length(var.name) >= 2 && length(var.name) <= 100
    error_message = "name doit faire 2-100 chars."
  }
}

variable "vpc_a_id" {
  type        = string
  description = "UUID d'un des deux VPCs. L'ordre n'a pas d'importance — le provider normalise."
}

variable "vpc_b_id" {
  type        = string
  description = "UUID de l'autre VPC (différent de vpc_a_id)."
}

variable "tags" {
  type    = list(string)
  default = []
}
