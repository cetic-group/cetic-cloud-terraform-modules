variable "name" {
  type        = string
  description = "Nom du bucket S3 (DNS-compatible : 3-63 chars, [a-z0-9-], commence/finit par alphanum)."
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "Nom de bucket invalide (S3 DNS rules)."
  }
}

variable "region" {
  type = string
  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "Région invalide."
  }
}

variable "is_public" {
  type        = bool
  default     = false
  description = "Si `true`, le bucket policy autorise un accès anonyme en lecture (assets publics)."
}

variable "scoped_keys" {
  description = <<-EOT
    Map de clés S3 scopées à créer (subusers RGW). Clé = label logique.

    Niveaux d'accès : `read` / `write` / `readwrite` / `full`.
    Les credentials sont sortis dans `output.scoped_keys` (sensitive).
  EOT
  type = map(object({
    access_level = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.scoped_keys : contains(["read", "write", "readwrite", "full"], v.access_level)
    ])
    error_message = "access_level doit être l'un de : read, write, readwrite, full."
  }
}

variable "tags" {
  type    = list(string)
  default = []
}
