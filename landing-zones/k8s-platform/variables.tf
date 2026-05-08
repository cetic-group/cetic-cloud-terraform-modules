variable "org_prefix" {
  type        = string
  description = "Préfixe métier (ex `acme`)."
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}[a-z0-9]$", var.org_prefix))
    error_message = "org_prefix doit matcher [a-z][a-z0-9-]+[a-z0-9], 3-32 chars."
  }
}

variable "region" {
  type = string
  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "Région invalide."
  }
}

# ─── K8s ──────────────────────────────────────────────────────────────────────
variable "k8s_version" {
  type    = string
  default = "v1.31.4"
}

variable "initial_pool_replicas" {
  type        = number
  default     = 2
  description = "Replicas du pool initial du cluster K8s."
}

variable "initial_pool_plan" {
  type    = string
  default = "small"
}

variable "additional_pools" {
  description = "Pools additionnels passés au module managed/k8s-cluster (cf. son README pour le schéma)."
  type = map(object({
    plan     = string
    replicas = number
    min_size = optional(number)
    max_size = optional(number)
    labels   = optional(map(string), {})
  }))
  default = {}
}

variable "expose_apiserver_publicly" {
  type        = bool
  default     = false
  description = "Si `true`, attache une IP publique à l'apiserver (kubeconfig public)."
}

variable "ingress_scope" {
  type        = string
  default     = "external"
  description = "`external` (IP publique) ou `internal`."
}

# ─── Database optionnelle ─────────────────────────────────────────────────────
variable "enable_database" {
  type        = bool
  default     = true
  description = "Provisionne une instance PostgreSQL managée dans le VNet `data` à côté du cluster K8s."
}

variable "db_plan" {
  type    = string
  default = "small"
}

variable "db_replicas" {
  type    = number
  default = 1
  validation {
    condition     = contains([1, 3], var.db_replicas)
    error_message = "db_replicas doit être 1 ou 3."
  }
}

variable "db_storage_gb" {
  type    = number
  default = 20
}

variable "tags_extra" {
  type    = list(string)
  default = []
}
