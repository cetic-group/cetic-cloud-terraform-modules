variable "appgw_id" {
  type        = string
  description = "UUID de l'Application Gateway parente."
}

variable "name" {
  type        = string
  description = "Nom du target group (1-100 chars, unique par AppGW)."

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9_-]{0,99}$", var.name))
    error_message = "`name` doit commencer par alphanumérique et ne contenir que [a-zA-Z0-9_-]."
  }
}

variable "algorithm" {
  type        = string
  default     = "roundrobin"
  description = "Algorithme L7 : `roundrobin` / `leastconn` / `source`."

  validation {
    condition     = contains(["roundrobin", "leastconn", "source"], var.algorithm)
    error_message = "`algorithm` doit être `roundrobin`, `leastconn` ou `source`."
  }
}

# ── Health check ──────────────────────────────────────────────────────────────

variable "health_check" {
  description = <<-EOT
    Configuration du health check L7.
    Champs :
    - `protocol` : `http` / `https` / `tcp` (défaut `http`).
    - `method` : méthode HTTP (défaut `GET`).
    - `path` : path à hit (défaut `/`).
    - `expect_status` : code HTTP attendu (défaut `200`).
    - `interval_sec` : 1-300 (défaut `5`).
    - `timeout_sec` : 1-60 (défaut `3`).
    - `healthy_threshold` : 1-10 (défaut `2`).
    - `unhealthy_threshold` : 1-10 (défaut `3`).
  EOT

  type = object({
    protocol            = optional(string, "http")
    method              = optional(string, "GET")
    path                = optional(string, "/")
    expect_status       = optional(number, 200)
    interval_sec        = optional(number, 5)
    timeout_sec         = optional(number, 3)
    healthy_threshold   = optional(number, 2)
    unhealthy_threshold = optional(number, 3)
  })
  default = {}

  validation {
    condition     = contains(["http", "https", "tcp"], var.health_check.protocol)
    error_message = "`health_check.protocol` doit être `http`, `https` ou `tcp`."
  }
  validation {
    condition     = var.health_check.interval_sec >= 1 && var.health_check.interval_sec <= 300
    error_message = "`health_check.interval_sec` doit être entre 1 et 300."
  }
  validation {
    condition     = var.health_check.timeout_sec >= 1 && var.health_check.timeout_sec <= 60
    error_message = "`health_check.timeout_sec` doit être entre 1 et 60."
  }
  validation {
    condition     = var.health_check.healthy_threshold >= 1 && var.health_check.healthy_threshold <= 10
    error_message = "`health_check.healthy_threshold` doit être entre 1 et 10."
  }
  validation {
    condition     = var.health_check.unhealthy_threshold >= 1 && var.health_check.unhealthy_threshold <= 10
    error_message = "`health_check.unhealthy_threshold` doit être entre 1 et 10."
  }
}

# ── Sticky session ────────────────────────────────────────────────────────────

variable "sticky_enabled" {
  type        = bool
  default     = false
  description = "Active le sticky session (cookie-based)."
}

variable "sticky_cookie_name" {
  type        = string
  default     = null
  description = "Nom du cookie de session (requis si `sticky_enabled=true`)."
}

# ── Members ───────────────────────────────────────────────────────────────────

variable "members" {
  description = <<-EOT
    Map de members du target group. Clé = label logique (stable pour les drift).

    Champs (exactement un de container_id / vm_instance_id / target_ip) :
    - `container_id` : UUID d'un container.
    - `vm_instance_id` : UUID d'une VM.
    - `target_ip` : IP raw dans le VNet (string IPv4).
    - `port` : 1-65535 (requis).
    - `weight` : 0-1000 (défaut `100`).
    - `enabled` : (défaut `true`).
  EOT

  type = map(object({
    container_id   = optional(string)
    vm_instance_id = optional(string)
    target_ip      = optional(string)
    port           = number
    weight         = optional(number, 100)
    enabled        = optional(bool, true)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.members :
      (v.container_id != null ? 1 : 0) +
      (v.vm_instance_id != null ? 1 : 0) +
      (v.target_ip != null ? 1 : 0) == 1
    ])
    error_message = "Chaque member doit avoir exactement un de `container_id`, `vm_instance_id` ou `target_ip`."
  }

  validation {
    condition = alltrue([
      for k, v in var.members : v.port >= 1 && v.port <= 65535
    ])
    error_message = "Chaque member doit avoir un `port` entre 1 et 65535."
  }

  validation {
    condition = alltrue([
      for k, v in var.members : v.weight >= 0 && v.weight <= 1000
    ])
    error_message = "Chaque member doit avoir un `weight` entre 0 et 1000."
  }
}
