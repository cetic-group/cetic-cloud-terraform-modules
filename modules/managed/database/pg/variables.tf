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
  default     = "16"
  description = "Version majeure PostgreSQL. Cf. `data.ccp_db_engine_versions{engine=\"pg\"}`."
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "allowed_extensions" {
  type        = set(string)
  default     = null
  description = "Extensions du catalogue (`data.ccp_db_pg_extensions`) que le propriétaire de la base peut créer avec `CREATE EXTENSION`. Lister aussi leurs dépendances. Retirer une extension est refusé tant qu'elle est installée dans une base. `null` (défaut) : inchangé ; `[]` : aucune autorisée. Exige que les extensions soient activées sur l'instance (output `extensions_available`)."
}

variable "preload_libraries" {
  type        = set(string)
  default     = null
  description = "Bibliothèques chargées au démarrage, requises par certaines extensions (`pg_cron`, `pg_stat_statements`). Un changement redémarre l'instance, un replica à la fois. `null` (défaut) : inchangé ; `[]` : aucune."
}

variable "cron_database" {
  type        = string
  default     = null
  description = "Base dans laquelle `pg_cron` exécute les tâches planifiées. Exige `pg_cron` dans `preload_libraries`. `null` (défaut) : inchangé (base initiale de l'instance à la création)."
}
