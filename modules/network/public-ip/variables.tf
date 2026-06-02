variable "region" {
  type        = string
  description = "Région où allouer l'IP publique."
  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "La région doit être l'une de : RNN, PAR, ABJ."
  }
}

variable "pool_id" {
  type        = string
  default     = null
  description = "UUID du pool d'IPs source. `null` = laisse l'API choisir le 1er pool dispo de la région."
}

variable "quantity" {
  type        = number
  default     = 1
  description = "Nombre d'IPs publiques à allouer (1 à 8). Quand > 1, le label est suffixé -1, -2, …"
  validation {
    condition     = var.quantity >= 1 && var.quantity <= 8
    error_message = "quantity doit être entre 1 et 8."
  }
}

variable "label" {
  type        = string
  default     = null
  description = "Nom optionnel de l'IP (ex : passerelle-prod, ip-fixe-api). Max 100 caractères."
}

variable "description" {
  type        = string
  default     = null
  description = "Description optionnelle — à quoi sert cette IP ?"
}
