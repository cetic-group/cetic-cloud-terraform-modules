# Access policies #1828. No default silently clears an imported policy.

variable "l4_policy" {
  type = object({
    enabled = optional(bool)
    tcp_80  = optional(object({ allow_cidrs = optional(list(string)), deny_cidrs = optional(list(string)) }))
    tcp_443 = optional(object({ allow_cidrs = optional(list(string)), deny_cidrs = optional(list(string)) }))
  })
  default     = null
  description = "Politique d’accès typée. null/omise conserve la protection distante ; {} la supprime explicitement. Requiert la capacité API v1 et le provider 8.1.0."
}

variable "l7_policy" {
  type = object({
    enabled = optional(bool)
    policies = optional(map(object({
      scope = optional(object({ path = optional(object({ op = string, value = string })) }))
      allow_rules = optional(map(object({ match = object({
        source_cidrs = optional(list(string))
        path         = optional(object({ op = string, value = string }))
        methods      = optional(list(string))
        headers      = optional(list(object({ name = string, op = string, values = optional(list(string)) })))
        match_all    = optional(bool)
      }) })))
      deny_rules = optional(map(object({ match = object({
        source_cidrs = optional(list(string))
        path         = optional(object({ op = string, value = string }))
        methods      = optional(list(string))
        headers      = optional(list(object({ name = string, op = string, values = optional(list(string)) })))
        match_all    = optional(bool)
      }) })))
      required_headers = optional(map(object({ name = string, op = string, values = optional(list(string)) })))
    })))
  })
  default     = null
  description = "Politique d’accès typée. null/omise conserve la protection distante ; {} la supprime explicitement. Requiert la capacité API v1 et le provider 8.1.0."
}

variable "client_ip_policy" {
  type        = object({ mode = optional(string), trusted_proxy_cidrs = optional(list(string)) })
  default     = null
  description = "Politique d’accès typée. null/omise conserve la protection distante ; {} la supprime explicitement. Requiert la capacité API v1 et le provider 8.1.0."
}

variable "listener_l7_policies" {
  type = map(object({
    enabled = optional(bool)
    policies = optional(map(object({
      scope = optional(object({ path = optional(object({ op = string, value = string })) }))
      allow_rules = optional(map(object({ match = object({
        source_cidrs = optional(list(string))
        path         = optional(object({ op = string, value = string }))
        methods      = optional(list(string))
        headers      = optional(list(object({ name = string, op = string, values = optional(list(string)) })))
        match_all    = optional(bool)
      }) })))
      deny_rules = optional(map(object({ match = object({
        source_cidrs = optional(list(string))
        path         = optional(object({ op = string, value = string }))
        methods      = optional(list(string))
        headers      = optional(list(object({ name = string, op = string, values = optional(list(string)) })))
        match_all    = optional(bool)
      }) })))
      required_headers = optional(map(object({ name = string, op = string, values = optional(list(string)) })))
    })))
  }))
  default     = {}
  description = "Politiques HTTP par hostname exact. Une clé absente conserve la protection ; {} comme valeur remet ce listener à zéro."
  validation {
    condition     = alltrue([for hostname in keys(var.listener_l7_policies) : contains(var.hostnames, hostname)])
    error_message = "Chaque clé de listener_l7_policies doit figurer dans hostnames."
  }
}

