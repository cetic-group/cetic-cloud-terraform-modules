variable "name" {
  type        = string
  description = "Nom de l'instance Windows."
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
  default     = "medium"
  description = "Plan instance Windows (nano/micro/small/medium/large/xlarge). ATTENTION : Windows requiert au minimum medium (3 vCPU / 6 Go)."
  validation {
    condition     = contains(["nano", "micro", "small", "medium", "large", "xlarge"], var.plan)
    error_message = "Plan invalide."
  }
}

variable "template" {
  type        = string
  description = "Version Windows (clé de template, ex: windows-11-pro, windows-2022-datacenter)."
}

variable "vnet_id" {
  type        = string
  default     = null
  description = "UUID du VNet où rattacher l'instance."
}

variable "public_ip_id" {
  type        = string
  default     = null
  description = "UUID de l'IP publique à attacher (optionnel)."
}

variable "administrator_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe administrateur injecté (8–128 caractères)."
  validation {
    condition     = length(var.administrator_password) >= 8 && length(var.administrator_password) <= 128
    error_message = "administrator_password doit faire entre 8 et 128 caractères."
  }
}

variable "data_volume_ids" {
  type        = list(string)
  default     = []
  description = "UUIDs des volumes de données à attacher (figé au create, max 5)."
  validation {
    condition     = length(var.data_volume_ids) <= 5
    error_message = "Maximum 5 disques de données autorisés."
  }
}

variable "tags" {
  type        = list(string)
  default     = []
  description = "Tags associés à l'instance."
}

variable "license_consent" {
  type        = bool
  default     = false
  description = "Consentement à l'utilisation de Windows. CETIC Cloud Platform ne fournit aucune licence Windows — vous acceptez que vous êtes responsable de la licence."
  validation {
    condition     = var.license_consent == true
    error_message = "Vous devez accepter la licence Windows (license_consent = true). CETIC Cloud Platform ne fournit aucune licence Windows — vous êtes responsable de sa fourniture."
  }
}
