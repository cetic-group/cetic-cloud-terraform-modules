variable "name" {
  type        = string
  description = "Nom de l'Application Gateway (1-100 caractères)."

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 100
    error_message = "`name` doit faire entre 1 et 100 caractères."
  }
}

variable "region" {
  type        = string
  description = "Région CETIC Cloud : `RNN`, `PAR` ou `ABJ`."

  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "La région doit être `RNN`, `PAR` ou `ABJ`."
  }
}

variable "plan" {
  type        = string
  default     = "small"
  description = "Plan de l'AppGW : `small` / `medium` / `large`. Détermine routes max, listeners max, rate limit max, WAF."

  validation {
    condition     = contains(["small", "medium", "large"], var.plan)
    error_message = "`plan` doit être l'un de : small, medium, large."
  }
}

variable "vpc_id" {
  type        = string
  description = "UUID du VPC dans lequel héberger la gateway."
}

variable "vnet_id" {
  type        = string
  description = "UUID du VNet où héberger la VIP de l'AppGW. Les backends doivent être joignables depuis ce VNet."
}

variable "public_ip_id" {
  type        = string
  default     = null
  description = "UUID d'une IP publique (même région) à attacher à l'AppGW. `null` = gateway purement interne (utile pour API privées entre VNets)."
}

variable "force_https" {
  type        = bool
  default     = true
  description = "Si `true`, redirige automatiquement `:80` vers `:443` (sauf challenges ACME)."
}

variable "hsts_enabled" {
  type        = bool
  default     = false
  description = "Active l'en-tête `Strict-Transport-Security` sur les réponses HTTPS."
}

variable "hsts_max_age" {
  type        = number
  default     = 31536000
  description = "Valeur `max-age` HSTS en secondes (défaut 1 an)."

  validation {
    condition     = var.hsts_max_age >= 0 && var.hsts_max_age <= 63072000
    error_message = "`hsts_max_age` doit être entre 0 et 63072000 (2 ans)."
  }
}

variable "global_rate_limit_per_sec" {
  type        = number
  default     = null
  description = "Rate limit global par IP source en requêtes/seconde (`null` = pas de limite globale). Borné par le plan."

  validation {
    # try() évite l'évaluation eager de la 2e clause quand var est null.
    condition     = var.global_rate_limit_per_sec == null || try(var.global_rate_limit_per_sec > 0 && var.global_rate_limit_per_sec <= 100000, false)
    error_message = "`global_rate_limit_per_sec` doit être > 0 et <= 100000, ou `null`."
  }
}

variable "global_allow_cidrs" {
  type        = list(string)
  default     = []
  description = "Liste de CIDR autorisés globalement. Vide = pas de filtrage allow-list. Exclu mutuellement avec `global_deny_cidrs` au niveau du même CIDR."

  validation {
    condition = alltrue([
      for c in var.global_allow_cidrs : can(cidrhost(c, 0))
    ])
    error_message = "`global_allow_cidrs` doit contenir des CIDR valides."
  }
}

variable "global_deny_cidrs" {
  type        = list(string)
  default     = []
  description = "Liste de CIDR refusés globalement (priorité sur allow)."

  validation {
    condition = alltrue([
      for c in var.global_deny_cidrs : can(cidrhost(c, 0))
    ])
    error_message = "`global_deny_cidrs` doit contenir des CIDR valides."
  }
}

variable "trust_proxy_headers" {
  type        = bool
  default     = false
  description = "Si `true`, accepte les en-têtes `X-Forwarded-For` / `X-Real-IP` en entrée (à activer uniquement si l'AppGW est derrière un autre proxy de confiance)."
}

variable "tags" {
  type        = list(string)
  default     = []
  description = "Liste de tags free-form (max 60, max 50 chars chacun)."
}
