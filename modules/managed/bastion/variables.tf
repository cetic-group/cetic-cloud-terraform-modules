# ── Bastion core ──────────────────────────────────────────────────────────────

variable "name" {
  description = "Nom de base du bastion SSH (1–100 chars ; lettres, chiffres, `_`, `-`, espaces). Immutable — force replacement."
  type        = string
  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 100
    error_message = "`name` doit faire entre 1 et 100 caractères."
  }
  validation {
    condition     = can(regex("^[a-zA-Z0-9_ -]+$", var.name))
    error_message = "`name` ne peut contenir que des lettres, chiffres, `_`, `-` et espaces."
  }
}

variable "region" {
  description = "Région CETIC Cloud : `RNN` / `PAR` / `ABJ`. Immutable — force replacement."
  type        = string
  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "La région doit être `RNN`, `PAR` ou `ABJ`."
  }
}

variable "plan" {
  description = "Plan du bastion : `small` (défaut) / `medium` / `large`."
  type        = string
  default     = "small"
  validation {
    condition     = contains(["small", "medium", "large"], var.plan)
    error_message = "`plan` doit être l'un de : small, medium, large."
  }
}

# Deux façons de rattacher le bastion à un ou plusieurs VPC. Fournissez
# `vpc_ids` (un ou plusieurs VPC à exposer) OU `vpc_id` (raccourci pour un seul).
variable "vpc_ids" {
  description = <<-EOT
    Liste des UUID de VPC dont les instances privées sont joignables à travers
    le bastion. Au moins un VPC est requis. Utilisez `vpc_id` à la place pour un
    VPC unique. Immutable — force replacement.
  EOT
  type        = list(string)
  default     = null
}

variable "vpc_id" {
  description = "Raccourci pour un seul VPC. Ignoré si `vpc_ids` est fourni. Immutable — force replacement."
  type        = string
  default     = null
}

variable "public_ip_id" {
  description = "UUID d'une IP publique à attacher comme point d'entrée SSH du bastion. `null` = la plateforme alloue automatiquement un point d'entrée public."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags free-form (max 60, max 50 chars chacun)."
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.tags) <= 60
    error_message = "`tags` peut contenir au plus 60 entrées."
  }
  validation {
    condition     = alltrue([for t in var.tags : length(t) <= 50])
    error_message = "Chaque tag doit faire au plus 50 caractères."
  }
}
