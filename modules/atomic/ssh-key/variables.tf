variable "name" {
  type        = string
  description = "Nom de la clé SSH (visible dans la console et dans la liste `ssh_key_ids` des instances)."

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 100
    error_message = "Le nom de la clé doit faire entre 1 et 100 caractères."
  }
}

variable "public_key" {
  type        = string
  description = "Contenu de la clé publique au format OpenSSH. Préférer `file(\"~/.ssh/id_ed25519.pub\")` pour ne pas la dupliquer."

  validation {
    condition     = can(regex("^(ssh-(rsa|ed25519|dss)|ecdsa-sha2-nistp(256|384|521)) ", var.public_key))
    error_message = "La clé publique doit commencer par un type OpenSSH valide (ssh-rsa, ssh-ed25519, ecdsa-sha2-*, ssh-dss)."
  }
}

variable "scope" {
  type        = string
  default     = "user"
  description = "Visibilité de la clé : `user` (créateur seul, défaut), `org` (membres de l'organisation active), `tenant` (toutes orgs du compte). Immuable côté provider — recréation forcée si modifié."

  validation {
    condition     = contains(["user", "org", "tenant"], var.scope)
    error_message = "Le scope doit être l'un de : user, org, tenant."
  }
}
