variable "name" {
  type        = string
  description = "Nom du container (1-80 chars)."
}

variable "region" {
  type        = string
  description = "Région : `RNN`, `PAR`, `ABJ`."
  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "Région invalide."
  }
}

variable "plan" {
  type        = string
  default     = "small"
  description = "Plan : `nano` / `micro` / `small` / `medium` / `large` / `xlarge`."
  validation {
    condition     = contains(["nano", "micro", "small", "medium", "large", "xlarge"], var.plan)
    error_message = "Plan invalide."
  }
}

variable "template" {
  type        = string
  default     = "ubuntu-24.04"
  description = "Clé du template OS (catalogue système ou UUID d'un custom template)."
}

variable "vnet_id" {
  type        = string
  description = "UUID du VNet."
}

variable "ssh_key_ids" {
  type        = list(string)
  default     = []
  description = "Liste d'UUIDs de clés SSH à injecter (cf. module `atomic/ssh-key`)."
}

variable "user_data" {
  type        = string
  default     = null
  description = "Cloud-init user-data (bash script ou cloud-config YAML)."
}

variable "public_ip_id" {
  type        = string
  default     = null
  description = "UUID d'une IP publique à attacher. `null` = container privé."
}

variable "root_password" {
  type        = string
  default     = null
  sensitive   = true
  description = "Mot de passe root explicite. `null` = généré côté serveur."
}

variable "tags" {
  type    = list(string)
  default = []
}
