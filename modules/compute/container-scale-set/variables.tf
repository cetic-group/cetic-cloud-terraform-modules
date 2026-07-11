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

variable "root_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe root injecté à la création sur chaque container du scale set (8–128 caractères)."
  validation {
    condition     = length(var.root_password) >= 8 && length(var.root_password) <= 128
    error_message = "root_password doit faire entre 8 et 128 caractères."
  }
}

variable "disk_gb" {
  type        = number
  default     = null
  description = <<-EOT
    Taille du disque racine en GB, appliquée à chaque réplica du scale set.
    `null` = taille par défaut du plan choisi (`plan`). Grow-only : une valeur
    supérieure à la taille courante redimensionne le disque en place ; une
    valeur inférieure est refusée par l'API (422).
  EOT
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "bastion_access" {
  type        = bool
  default     = false
  description = "Autoriser l'accès SSH via le Bastion du tenant sur chaque réplica (opt-in). Forces new resource."
}

variable "docker" {
  type        = bool
  default     = false
  description = "Activer Docker (nesting) sur chaque réplica (opt-in). Désactivé = réplicas durcis contre la fuite de topologie de l'hôte. Forces new resource."
}
