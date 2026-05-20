variable "org_prefix" {
  type        = string
  description = "Préfixe métier appliqué à toutes les ressources (ex `acme` → `acme-prod-vpc`, `acme-prod-lb`, …)."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}[a-z0-9]$", var.org_prefix))
    error_message = "`org_prefix` doit commencer par une lettre, ne contenir que [a-z0-9-], 3-32 chars, terminer par lettre/chiffre."
  }
}

variable "region" {
  type        = string
  description = "Région CETIC Cloud : `RNN`, `PAR` ou `ABJ`."

  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "La région doit être l'une de : RNN, PAR, ABJ."
  }
}

variable "ssh_public_key" {
  type        = string
  description = "Contenu de la clé publique SSH OpenSSH (utilise `file(\"~/.ssh/id_ed25519.pub\")`)."
}

variable "app_root_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe root injecté sur chaque container d'app à la création (8–128 caractères)."
  validation {
    condition     = length(var.app_root_password) >= 8 && length(var.app_root_password) <= 128
    error_message = "`app_root_password` doit faire entre 8 et 128 caractères."
  }
}

# ─── Application web ──────────────────────────────────────────────────────────
variable "app_plan" {
  type        = string
  default     = "small"
  description = "Plan d'instance pour les containers de l'app. Un de `nano`/`micro`/`small`/`medium`/`large`/`xlarge`."
}

variable "app_template" {
  type        = string
  default     = "ubuntu-24.04"
  description = "Template OS des containers (clé du catalogue, voir `data.ccp_lxc_templates`)."
}

variable "app_replicas" {
  type        = number
  default     = 2
  description = "Nombre de containers de l'app derrière le LB."

  validation {
    condition     = var.app_replicas >= 1 && var.app_replicas <= 20
    error_message = "`app_replicas` doit être entre 1 et 20."
  }
}

variable "app_listen_port" {
  type        = number
  default     = 8080
  description = "Port d'écoute de l'app sur chaque container (envoyé en `backend.port` au LB)."
}

# ─── Base de données ──────────────────────────────────────────────────────────
variable "enable_database" {
  type        = bool
  default     = true
  description = "Si `true`, provisionne une instance PostgreSQL managée dans le VNet `data`."
}

variable "db_plan" {
  type        = string
  default     = "small"
  description = "Plan PostgreSQL : `nano` à `xlarge`."
}

variable "db_replicas" {
  type        = number
  default     = 1
  description = "Nombre de replicas PostgreSQL. `1` = tier dev (sans HA). `3` = tier prod (HA avec anti-affinity). Le `tier` est dérivé automatiquement par l'API selon ce nombre."

  validation {
    condition     = contains([1, 3], var.db_replicas)
    error_message = "`db_replicas` doit être `1` (dev) ou `3` (prod)."
  }
}

variable "db_engine_version" {
  type        = string
  default     = "16"
  description = "Version majeure PostgreSQL (cf. `data.ccp_db_engine_versions`)."
}

variable "db_storage_gb" {
  type        = number
  default     = 20
  description = "Taille du stockage PG en GB."

  validation {
    condition     = var.db_storage_gb >= 1 && var.db_storage_gb <= 1000
    error_message = "`db_storage_gb` doit être entre 1 et 1000."
  }
}

# ─── Exposition publique ──────────────────────────────────────────────────────
variable "exposure_type" {
  type        = string
  default     = "lb"
  description = <<-EOT
    Mode d'exposition publique de l'app :
    - `"lb"` (défaut, rétrocompat) : Load Balancer L4 (TCP) — HTTP sur :80, optionnellement HTTPS sur :443 (TLS terminé côté app).
    - `"appgw"` : Application Gateway L7 (HTTP/HTTPS) — TLS terminé côté gateway (cert Let's Encrypt auto), routing path-based, policies, HSTS, rate limit, WAF.

    Si `"appgw"`, configurer aussi `appgw_hostname` (et `appgw_plan` si autre que `small`).
  EOT

  validation {
    condition     = contains(["lb", "appgw"], var.exposure_type)
    error_message = "`exposure_type` doit être `lb` ou `appgw`."
  }
}

variable "expose_https" {
  type        = bool
  default     = false
  description = "Si `true` et `exposure_type=\"lb\"`, ajoute un listener TCP/443 (TLS terminé côté app). Ignoré quand `exposure_type=\"appgw\"` (l'AppGW termine HTTPS nativement)."
}

variable "lb_plan" {
  type        = string
  default     = "small"
  description = <<-EOT
    Plan de capacité du Load Balancer (utilisé si `exposure_type=\"lb\"`).
    `small` (défaut) / `medium` / `large` — cf. module `exposure/load-balancer`
    pour les specs détaillées. Immuable : changer de plan force le remplacement
    du LB.
  EOT

  validation {
    condition     = contains(["small", "medium", "large"], var.lb_plan)
    error_message = "`lb_plan` doit être `small`, `medium` ou `large`."
  }
}

# ── Configuration AppGW (utilisée si exposure_type = "appgw") ──
variable "appgw_hostname" {
  type        = string
  default     = null
  description = "Hostname exposé par l'AppGW (FQDN). Si `null` et `exposure_type=\"appgw\"`, l'API génère un sous-domaine auto `.app.cloud.cetic-group.com`."
}

variable "appgw_plan" {
  type        = string
  default     = "small"
  description = "Plan de l'AppGW : `small` / `medium` / `large`."

  validation {
    condition     = contains(["small", "medium", "large"], var.appgw_plan)
    error_message = "`appgw_plan` doit être `small`, `medium` ou `large`."
  }
}

variable "appgw_custom_domain" {
  type        = bool
  default     = false
  description = "Si `true`, `appgw_hostname` est un domaine client (CNAME requis avant apply). Sinon sous-domaine auto."
}

variable "appgw_hsts_enabled" {
  type        = bool
  default     = true
  description = "Active HSTS sur l'AppGW (recommandé en prod)."
}

variable "appgw_rate_limit_per_sec" {
  type        = number
  default     = null
  description = "Rate limit global par IP en req/s (`null` = pas de limite)."
}

variable "tags_extra" {
  type        = list(string)
  default     = []
  description = "Tags additionnels propagés à toutes les ressources créées (le module ajoute aussi `landing-zone:basic-web-app`)."
}
