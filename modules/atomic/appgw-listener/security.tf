# Access policies #1828. No default silently clears an imported policy.

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
