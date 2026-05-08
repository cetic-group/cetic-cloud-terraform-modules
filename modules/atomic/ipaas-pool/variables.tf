variable "region" {
  type        = string
  description = "Région du pool IPaaS."
  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "La région doit être l'une de : RNN, PAR, ABJ."
  }
}

variable "cidr" {
  type        = string
  description = "Bloc BYOIP (ex `163.172.232.192/27`)."
  validation {
    condition     = can(cidrhost(var.cidr, 0))
    error_message = "`cidr` doit être un CIDR valide."
  }
}

variable "gateway" {
  type        = string
  description = "Gateway du pool (1re IP utilisable, réservée par le routage Scaleway)."
}

variable "edge_id" {
  type        = string
  default     = null
  description = "UUID de l'edge IPaaS (Dedibox Scaleway). Optionnel — assignable après création."
}

variable "is_active" {
  type        = bool
  default     = true
  description = "Si `false`, le pool est désactivé (pas d'allocation d'IPs depuis ce pool)."
}
