variable "name" {
  type = string
}

variable "region" {
  type = string
  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "Région invalide."
  }
}

variable "vpc_id" {
  type = string
}

variable "vnet_id" {
  type = string
}

variable "plan" {
  type    = string
  default = "small"
  validation {
    condition     = contains(["nano", "micro", "small", "medium", "large", "xlarge"], var.plan)
    error_message = "Plan invalide."
  }
}

variable "storage_gb" {
  type    = number
  default = 20
  validation {
    condition     = var.storage_gb >= 1 && var.storage_gb <= 1000
    error_message = "storage_gb doit être entre 1 et 1000."
  }
}

variable "replicas" {
  type        = number
  default     = 1
  description = "Nombre de replicas. `1` = tier `dev` (sans HA). `3` = tier `prod` (HA avec anti-affinity). Le `tier` est dérivé automatiquement par l'API."
  validation {
    condition     = contains([1, 3], var.replicas)
    error_message = "replicas doit être 1 (dev) ou 3 (prod)."
  }
}

variable "engine_version" {
  type        = string
  default     = "2.7"
  description = "Version majeure FerretDB v2 (Mongo-compat). Cf. `data.ccp_db_engine_versions{engine=\"pg\"}`."
}

variable "tags" {
  type    = list(string)
  default = []
}
