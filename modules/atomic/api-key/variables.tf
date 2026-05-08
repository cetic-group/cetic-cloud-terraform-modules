variable "name" {
  type        = string
  description = "Nom de la clé API."
  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 100
    error_message = "Le nom doit faire 1-100 caractères."
  }
}

variable "scopes" {
  type        = list(string)
  description = "Scopes de la clé. Au moins un parmi `read`, `write`, `billing`, `admin`."
  validation {
    condition = alltrue([
      for s in var.scopes : contains(["read", "write", "billing", "admin"], s)
    ]) && length(var.scopes) > 0
    error_message = "Chaque scope doit être l'un de : read, write, billing, admin."
  }
}

variable "expires_in_days" {
  type        = number
  default     = null
  description = "Expiration en jours (1-3650). `null` = pas d'expiration."
  validation {
    condition     = var.expires_in_days == null || (var.expires_in_days >= 1 && var.expires_in_days <= 3650)
    error_message = "`expires_in_days` doit être entre 1 et 3650, ou null."
  }
}
