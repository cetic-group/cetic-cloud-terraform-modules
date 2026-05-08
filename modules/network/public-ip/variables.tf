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
