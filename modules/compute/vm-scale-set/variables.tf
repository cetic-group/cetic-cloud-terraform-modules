variable "name" {
  type = string
}

variable "region" {
  type = string
  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "Région invalide."
  }
}

variable "plan" {
  type    = string
  default = "small"
}

variable "template" {
  type    = string
  default = "ubuntu-24.04"
}

variable "vnet_id" {
  type = string
}

variable "min_instances" {
  type        = number
  description = "Nombre min de containers (0-50)."
  validation {
    condition     = var.min_instances >= 0 && var.min_instances <= 50
    error_message = "min_instances doit être entre 0 et 50."
  }
}

variable "max_instances" {
  type        = number
  description = "Nombre max (1-50, ≥ min_instances)."
  validation {
    condition     = var.max_instances >= 1 && var.max_instances <= 50
    error_message = "max_instances doit être entre 1 et 50."
  }
}

variable "desired_instances" {
  type        = number
  description = "Nombre cible (dans [min, max])."
}

variable "auto_repair" {
  type        = bool
  default     = true
  description = "Recrée automatiquement les instances en erreur ou stoppées."
}

variable "tags" {
  type    = list(string)
  default = []
}
