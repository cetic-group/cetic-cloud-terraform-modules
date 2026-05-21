variable "name" {
  type        = string
  description = "Nom de base de la gateway. Les listeners/target groups/routes en sont dérivés ou nommés via leur clé."
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
}

variable "vpc_id" {
  type        = string
  description = "UUID du VPC."
}

variable "vnet_id" {
  type        = string
  description = "UUID du VNet hébergeant la VIP."
}

variable "public_ip_id" {
  type        = string
  default     = null
  description = "UUID de l'IP publique à attacher. `null` = gateway interne."
}

variable "tags" {
  type    = list(string)
  default = []
}

# ── Gateway-level policies (pass-through vers atomic/application-gateway) ────

variable "force_https" {
  type    = bool
  default = true
}

variable "hsts_enabled" {
  type    = bool
  default = false
}

variable "hsts_max_age" {
  type    = number
  default = 31536000
}

variable "global_rate_limit_per_sec" {
  type    = number
  default = null
}

variable "global_allow_cidrs" {
  type    = list(string)
  default = []
}

variable "global_deny_cidrs" {
  type    = list(string)
  default = []
}

# ── Listeners ────────────────────────────────────────────────────────────────

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
    error_message = "Chaque hostname doit être un FQDN valide en lowercase."
  }
}

variable "custom_domain" {
  type        = bool
  default     = false
  description = "Si `true`, les hostnames sont des domaines client (CNAME requis). Si `false`, sous-domaine auto `.app.cloud.cetic-group.com`."
}

# ── Target groups ────────────────────────────────────────────────────────────

variable "target_groups" {
  description = <<-EOT
    Map de target groups. Clé = label logique (référencé par `routes[*].target_group_key`).
    Au moins une entrée requise (typiquement `default`).

    Champs :
    - `algorithm` : `roundrobin` / `leastconn` / `source` (défaut `roundrobin`).
    - `health_check` : object (cf. atomic/appgw-target-group).
    - `sticky_enabled` / `sticky_cookie_name` : optionnels.
    - `members` : map(object) (cf. atomic/appgw-target-group).
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

# ── Routes ───────────────────────────────────────────────────────────────────

variable "routes" {
  description = <<-EOT
    Liste de routes. Chaque route référence :
    - un listener par index (`listener_index` → `hostnames[listener_index]`)
    - un target group par clé (`target_group_key` → clé de `target_groups`)

    Policies route-level optionnelles via `policies` object.
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

  validation {
    condition     = length(var.routes) >= 1
    error_message = "Au moins une route est requise."
  }
}
