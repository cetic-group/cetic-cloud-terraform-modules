variable "email" {
  type        = string
  description = "Email du membre à inviter dans l'organisation."
  validation {
    condition     = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.email))
    error_message = "L'email doit être valide."
  }
}

variable "role" {
  type        = string
  description = "Rôle : `admin`, `member`, ou `viewer`. Pas `owner` (réservé au propriétaire racine)."
  validation {
    condition     = contains(["admin", "member", "viewer"], var.role)
    error_message = "Le rôle doit être l'un de : admin, member, viewer."
  }
}
