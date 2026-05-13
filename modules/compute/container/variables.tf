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
  sensitive   = true
  description = "Mot de passe root injecté à la création (8–128 caractères)."
  validation {
    condition     = length(var.root_password) >= 8 && length(var.root_password) <= 128
    error_message = "root_password doit faire entre 8 et 128 caractères."
  }
}

variable "tags" {
  type    = list(string)
  default = []
}
