# ── Gateway core ────────────────────────────────────────────────────────────

variable "name" {
  type        = string
  description = "Nom de base de la gateway."

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 100
    error_message = "`name` doit faire entre 1 et 100 caractères."
  }
}

variable "region" {
  type        = string
  description = "Région CETIC Cloud : `RNN` / `PAR` / `ABJ`."

  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "La région doit être `RNN`, `PAR` ou `ABJ`."
  }
}

variable "plan" {
  type        = string
  default     = "small"
  description = "Plan AppGW : `small` / `medium` / `large`."

  validation {
    condition     = contains(["small", "medium", "large"], var.plan)
    error_message = "`plan` doit être `small`, `medium` ou `large`."
  }
}

variable "vpc_id" {
  type        = string
  description = "UUID du VPC."
}

variable "vnet_id" {
  type        = string
  description = "UUID du VNet hébergeant la VIP de la gateway. Les backends doivent être joignables depuis ce VNet."
}

variable "public_ip_id" {
  type        = string
  default     = null
  description = "UUID de l'IP publique à attacher. `null` = gateway interne."
}

variable "tags" {
  type        = list(string)
  default     = []
  description = "Tags free-form (max 60, max 50 chars chacun)."
}

# ── Gateway-level policies ──────────────────────────────────────────────────

variable "force_https" {
  type        = bool
  default     = true
  description = "Redirection automatique HTTP → HTTPS."
}

variable "hsts_enabled" {
  type        = bool
  default     = false
  description = "Active HSTS sur les réponses HTTPS."
}

variable "hsts_max_age" {
  type        = number
  default     = 31536000
  description = "`max-age` HSTS en secondes (défaut 1 an)."
}

variable "global_rate_limit_per_sec" {
  type        = number
  default     = null
  description = "Rate limit global par IP source en req/s. `null` = pas de limite globale."
}

variable "global_allow_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDR autorisés globalement."
}

variable "global_deny_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDR refusés globalement (priorité sur allow)."
}

variable "trust_proxy_headers" {
  type        = bool
  default     = false
  description = "Accepte `X-Forwarded-For` / `X-Real-IP` en entrée (uniquement si l'AppGW est derrière un autre proxy de confiance)."
}

# ── Listeners ───────────────────────────────────────────────────────────────

variable "hostnames" {
  type        = list(string)
  description = <<-EOT
    Liste ordonnée de hostnames à exposer. 1 listener (et 1 cert ACME Let's Encrypt)
    par hostname. Les routes référencent les listeners par leur **index** dans cette liste
    via `routes[*].listener_index`.

    Exemple : `["api.example.com", "admin.example.com"]` → index 0, 1.
  EOT

  validation {
    condition     = length(var.hostnames) >= 1
    error_message = "Au moins un hostname est requis."
  }
  validation {
    condition = alltrue([
      for h in var.hostnames : can(regex("^[a-z0-9]([-a-z0-9.]{0,251}[a-z0-9])?$", h))
    ])
    error_message = "Chaque hostname doit être un FQDN valide en lowercase (RFC 1123, max 253 chars)."
  }
}

variable "acme_challenge" {
  type        = string
  default     = "http01"
  description = <<-EOT
    Type de challenge ACME (Let's Encrypt) appliqué à tous les listeners (hostnames) :
    `http01` (défaut) ou `dns01`. `null` = aucun certificat TLS émis.
    `dns01` requiert `acme_dns_provider` + `acme_dns_credentials` (et un CNAME du domaine client).
  EOT

  validation {
    condition     = var.acme_challenge == null ? true : contains(["http01", "dns01"], var.acme_challenge)
    error_message = "`acme_challenge` doit être `http01`, `dns01` ou null."
  }
}

variable "acme_dns_provider" {
  type        = string
  default     = null
  description = "Clé du provider DNS pour `dns01` (ex. `cloudflare`). Requis si `acme_challenge = \"dns01\"`."
}

variable "acme_dns_credentials" {
  type        = map(string)
  default     = null
  sensitive   = true
  description = "Credentials du provider DNS pour `dns01` (write-only). Requis si `acme_challenge = \"dns01\"`."
}

# ── Target groups ───────────────────────────────────────────────────────────

variable "target_groups" {
  description = <<-EOT
    Map de target groups. Clé = label logique (référencé par `routes[*].target_group_key`).
    Au moins une entrée requise (typiquement `default`).

    Schéma — voir `atomic/appgw-target-group` :
    - `algorithm` : `roundrobin` / `leastconn` / `source` (défaut `roundrobin`)
    - `health_check` : object (protocol, method, path, expect_status, interval_sec, timeout_sec, …)
    - `sticky_enabled` / `sticky_cookie_name`
    - `members` : map(object) — exactement un de container_id / vm_instance_id / target_ip par member
  EOT

  type = map(object({
    algorithm = optional(string, "roundrobin")
    health_check = optional(object({
      protocol            = optional(string, "http")
      method              = optional(string, "GET")
      path                = optional(string, "/")
      expect_status       = optional(number, 200)
      interval_sec        = optional(number, 5)
      timeout_sec         = optional(number, 3)
      healthy_threshold   = optional(number, 2)
      unhealthy_threshold = optional(number, 3)
    }), {})
    sticky_enabled     = optional(bool, false)
    sticky_cookie_name = optional(string)
    members = map(object({
      container_id   = optional(string)
      vm_instance_id = optional(string)
      target_ip      = optional(string)
      port           = number
      weight         = optional(number, 100)
      enabled        = optional(bool, true)
    }))
  }))

  validation {
    condition     = length(var.target_groups) >= 1
    error_message = "Au moins un target group est requis."
  }
}

# ── Routes ──────────────────────────────────────────────────────────────────

variable "routes" {
  description = <<-EOT
    Liste de routes. Chaque route référence :
    - un listener par index (`listener_index` → `hostnames[listener_index]`)
    - un target group par clé (`target_group_key` → clé de `target_groups`)

    Policies route-level optionnelles via `policies` object. `basic_auth_users` est
    sensible (mots de passe en clair dans le state — voir doc atomic/appgw-route).
  EOT

  type = list(object({
    listener_index   = number
    target_group_key = string
    priority         = optional(number, 100)
    path_match       = optional(string, "/")
    path_match_type  = optional(string, "prefix")
    method_match     = optional(list(string), [])
    strip_prefix     = optional(bool, false)
    header_matches = optional(list(object({
      name  = string
      value = string
      op    = optional(string, "eq")
    })), [])
    policies = optional(object({
      rate_limit_per_sec = optional(number)
      allow_cidrs        = optional(list(string), [])
      deny_cidrs         = optional(list(string), [])
      request_headers    = optional(map(string), {})
      response_headers   = optional(map(string), {})
      cors_enabled       = optional(bool, false)
      cors_origins       = optional(list(string), [])
      cors_methods       = optional(list(string), ["GET", "POST", "PUT", "DELETE", "OPTIONS"])
      cors_credentials   = optional(bool, false)
      basic_auth_users = optional(list(object({
        user     = string
        password = string
      })))
      waf_preset = optional(string, "off")
    }), {})
  }))
  # `routes` n'est pas marquée `sensitive = true` au niveau variable car
  # cela poison toutes les références (`length(var.routes)`, `module.routes[*].id`)
  # et empêche les `assert` plan-time. Le sub-input `basic_auth_users` est
  # propagé vers le sous-module `atomic/appgw-route` qui le marque sensitive
  # individuellement — le password reste protégé dans le state.

  validation {
    condition     = length(var.routes) >= 1
    error_message = "Au moins une route est requise."
  }
}
