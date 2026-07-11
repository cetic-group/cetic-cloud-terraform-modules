variable "name" {
  type        = string
  description = "Nom de la VM."
}

variable "region" {
  type        = string
  description = "Région."
  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "Région invalide."
  }
}

variable "plan" {
  type        = string
  default     = "small"
  description = "Plan instance VM (nano/micro/small/medium/large/xlarge)."
}

variable "template" {
  type        = string
  default     = "ubuntu-24.04"
  description = "Template QEMU (clé catalogue ou UUID custom)."
}

variable "vnet_id" {
  type = string
}

variable "ssh_key_ids" {
  type    = list(string)
  default = []
}

variable "user_data" {
  type    = string
  default = null
}

variable "public_ip_id" {
  type    = string
  default = null
}

variable "root_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe root injecté via cloud-init (8–128 caractères)."
  validation {
    condition     = length(var.root_password) >= 8 && length(var.root_password) <= 128
    error_message = "root_password doit faire entre 8 et 128 caractères."
  }
}

variable "disk_gb" {
  type        = number
  default     = null
  description = <<-EOT
    Taille du disque racine en GB. `null` = taille par défaut du plan choisi
    (`plan`). Grow-only : une valeur supérieure à la taille courante
    redimensionne le disque en place ; une valeur inférieure est refusée par
    l'API (422).
  EOT
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "bastion_access" {
  type        = bool
  default     = false
  description = "Autoriser l'accès SSH via le Bastion du tenant (opt-in). Forces new resource."
}

variable "windows_license_consent" {
  type        = bool
  default     = false
  description = <<-EOT
    Reconnaître que CETIC Cloud ne fournit pas les licences Windows (vous devez
    détenir une licence valide par instance). Obligatoire (`true`) lorsque
    `template` est une image système Windows (`win-*`) ou un template custom
    capturé depuis une VM Windows — l'API renvoie une erreur 422 sinon. Ignoré
    pour les templates Linux. Une VM Windows exige aussi un plan `medium`+ et un
    mot de passe administrateur fort (≥ 12 caractères, ≥ 3 catégories). Forces new resource.
  EOT
}
