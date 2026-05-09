variable "vpc_map" {
  type = map(object({
    region = string
    vnets = map(object({
      cidr     = string
      snat     = bool
      tags     = list(string)
      isolated = optional(bool, false)
      ip_reservations = optional(map(object({
        ip          = string
        range_end   = optional(string)
        description = optional(string)
      })), {})
      firewall_rules = optional(list(object({
        direction   = string
        protocol    = optional(string, "tcp")
        source_cidr = optional(string)
        dest_cidr   = optional(string)
        port        = optional(string)
        description = optional(string)
      })), [])
    }))
  }))
}
