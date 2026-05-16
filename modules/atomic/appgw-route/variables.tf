variable "appgw_id" {
  type        = string
  description = "UUID de l'Application Gateway parente."
}

variable "listener_id" {
  type        = string
  description = "UUID du listener (hostname + cert) auquel la route s'applique."
}

variable "target_group_id" {
  type        = string
  description = "UUID du target group vers lequel la route route le trafic."
}

variable "priority" {
  type        = number
  default     = 100
  description = "Ordre d'évaluation (entier asc — la plus basse priorité matche en premier). Doit être unique par AppGW."

  validation {
    condition     = var.priority >= 0 && var.priority <= 10000
    error_message = "`priority` doit être entre 0 et 10000."
  }
}

variable "path_match" {
  type        = string
  default     = "/"
  description = "Pattern de match du path. Sémantique selon `path_match_type` (prefix : `/api/`; exact : `/healthz`; regex : `^/v[0-9]+/`)."
}

variable "path_match_type" {
  type        = string
  default     = "prefix"
  description = "Mode de matching du path : `prefix` / `exact` / `regex`."

  validation {
    condition     = contains(["prefix", "exact", "regex"], var.path_match_type)
    error_message = "`path_match_type` doit être `prefix`, `exact` ou `regex`."
  }
}

variable "header_matches" {
  type = list(object({
    name  = string
    value = string
    op    = optional(string, "eq")
  }))
  default     = []
  description = "Conditions sur les headers de la requête. `op` : `eq` / `ne` / `regex` / `prefix` / `suffix`."

  validation {
    condition = alltrue([
      for h in var.header_matches : contains(["eq", "ne", "regex", "prefix", "suffix"], h.op)
    ])
    error_message = "`header_matches[*].op` doit être `eq`, `ne`, `regex`, `prefix` ou `suffix`."
  }
}

variable "method_match" {
  type        = list(string)
  default     = []
  description = "Liste des méthodes HTTP autorisées (vide = toutes). Ex. `[\"GET\", \"POST\"]`."

  validation {
    condition = alltrue([
      for m in var.method_match : contains(["GET", "POST", "PUT", "PATCH", "DELETE", "HEAD", "OPTIONS"], m)
    ])
    error_message = "Chaque méthode doit être une méthode HTTP standard en majuscules."
  }
}

# ── Policies route-level ──────────────────────────────────────────────────────

variable "rate_limit_per_sec" {
  type        = number
  default     = null
  description = "Rate limit route-level par IP source en req/s. `null` = hérite du global de la gateway."

  validation {
    condition     = var.rate_limit_per_sec == null || (var.rate_limit_per_sec > 0 && var.rate_limit_per_sec <= 100000)
    error_message = "`rate_limit_per_sec` doit être > 0 et <= 100000, ou `null`."
  }
}

variable "allow_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDR autorisés (uniquement pour cette route)."

  validation {
    condition = alltrue([
      for c in var.allow_cidrs : can(cidrhost(c, 0))
    ])
    error_message = "Tous les éléments de `allow_cidrs` doivent être des CIDR valides."
  }
}

variable "deny_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDR refusés (priorité sur allow)."

  validation {
    condition = alltrue([
      for c in var.deny_cidrs : can(cidrhost(c, 0))
    ])
    error_message = "Tous les éléments de `deny_cidrs` doivent être des CIDR valides."
  }
}

variable "request_headers" {
  type        = map(string)
  default     = {}
  description = "Headers à set sur la requête vers le backend. Ex. `{ \"X-Real-IP\" = \"%[src]\" }`."
}

variable "response_headers" {
  type        = map(string)
  default     = {}
  description = "Headers à set sur la réponse retournée au client."
}

variable "cors_enabled" {
  type        = bool
  default     = false
  description = "Active CORS sur cette route."
}

variable "cors_origins" {
  type        = list(string)
  default     = []
  description = "Origins autorisées (ex. `[\"https://app.example.com\"]` ou `[\"*\"]`). Ignoré si `cors_enabled=false`."
}

variable "cors_methods" {
  type        = list(string)
  default     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
  description = "Méthodes CORS autorisées. Ignoré si `cors_enabled=false`."
}

variable "cors_credentials" {
  type        = bool
  default     = false
  description = "Si `true`, `Access-Control-Allow-Credentials: true`. Incompatible avec `cors_origins=[\"*\"]`."
}

variable "basic_auth_users" {
  type = list(object({
    user     = string
    password = string
  }))
  default     = null
  sensitive   = true
  description = <<-EOT
    Liste d'identifiants `{user, password}` pour activer le HTTP Basic Auth sur la route.
    `null` ou `[]` désactive l'auth. Les mots de passe sont persistés **en clair** dans le state Terraform
    (et donc dans tout backend de state) — utiliser un backend chiffré (S3+KMS, Vault, etc.).
    Côté plateforme, ils sont hashés et stockés dans une entrée Secret Manager dont la référence opaque
    est exposée via l'output `basic_auth_secret_ref`.
  EOT

  validation {
    condition = var.basic_auth_users == null || alltrue([
      for u in var.basic_auth_users : length(u.user) >= 1 && length(u.user) <= 64
    ])
    error_message = "Chaque `user` doit faire entre 1 et 64 caractères."
  }

  validation {
    condition = var.basic_auth_users == null || alltrue([
      for u in var.basic_auth_users : length(u.password) >= 1 && length(u.password) <= 256
    ])
    error_message = "Chaque `password` doit faire entre 1 et 256 caractères."
  }
}

variable "waf_preset" {
  type        = string
  default     = "off"
  description = "Preset WAF : `off` / `permissive` / `strict`."

  validation {
    condition     = contains(["off", "permissive", "strict"], var.waf_preset)
    error_message = "`waf_preset` doit être `off`, `permissive` ou `strict`."
  }
}
