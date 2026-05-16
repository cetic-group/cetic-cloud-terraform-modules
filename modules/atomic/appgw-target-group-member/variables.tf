variable "appgw_id" {
  type        = string
  description = "UUID de l'Application Gateway parente. **Immutable**."
}

variable "target_group_id" {
  type        = string
  description = "UUID du target group dans lequel ajouter ce member. **Immutable**."
}

variable "container_id" {
  type        = string
  default     = null
  description = "UUID d'un container backend. Exactement un de `container_id` / `vm_instance_id` / `target_ip`. **Immutable**."
}

variable "vm_instance_id" {
  type        = string
  default     = null
  description = "UUID d'une VM backend. Exactement un de `container_id` / `vm_instance_id` / `target_ip`. **Immutable**."
}

variable "target_ip" {
  type        = string
  default     = null
  description = "IP raw IPv4/IPv6 dans le VNet de l'AppGW. Exactement un de `container_id` / `vm_instance_id` / `target_ip`. **Immutable**."
}

variable "port" {
  type        = number
  description = "Port du backend (1-65535). **Immutable**."

  validation {
    condition     = var.port >= 1 && var.port <= 65535
    error_message = "`port` doit être entre 1 et 65535."
  }
}

variable "weight" {
  type        = number
  default     = 100
  description = "Pondération du backend dans le load balancing (0-1000, défaut `100`). `0` draine le member."

  validation {
    condition     = var.weight >= 0 && var.weight <= 1000
    error_message = "`weight` doit être entre 0 et 1000."
  }
}

variable "enabled" {
  type        = bool
  default     = true
  description = "Si `false`, le member est administrativement désactivé et skip par la gateway (utile pour drain manuel)."
}
