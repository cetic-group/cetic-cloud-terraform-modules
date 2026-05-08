variable "name" {
  type        = string
  description = "Nom du load balancer."
}

variable "region" {
  type = string
  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "Région invalide."
  }
}

variable "vnet_id" {
  type        = string
  description = "UUID du VNet où héberger la VIP. Les backends doivent être joignables depuis ce VNet."
}

variable "public_ip_id" {
  type        = string
  default     = null
  description = "UUID de l'IP publique à attacher (même région). `null` = LB interne uniquement."
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "listeners" {
  description = <<-EOT
    Map de listeners à exposer. Clé = nom logique (= `name` du listener).

    Champs :
    - `algorithm` : `round_robin` | `least_conn` | `source_ip` (défaut `round_robin`).
    - `protocol` : `http` | `tcp` (défaut `tcp`).
    - `frontend_port` : port d'écoute public (1-65535).
    - `backends` : map de backends. Chaque clé = label logique. Valeur :
        - `container_id` (XOR) `vm_instance_id` : UUID du backend.
        - `port` : port destination sur le backend.
        - `weight` : optionnel, défaut 1.

    Note actuelle : le provider expose `container_id` / `vm_instance_id`
    uniquement. Pour des backends auto-managés via scale set, attendre
    provider v0.8.0+ (qui ajoute `scale_set_id`).
  EOT

  type = map(object({
    algorithm     = optional(string, "round_robin")
    protocol      = optional(string, "tcp")
    frontend_port = number
    backends = map(object({
      container_id   = optional(string)
      vm_instance_id = optional(string)
      port           = number
      weight         = optional(number, 1)
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.listeners : contains(["round_robin", "least_conn", "source_ip"], v.algorithm)
    ])
    error_message = "algorithm doit être round_robin, least_conn ou source_ip."
  }

  validation {
    condition = alltrue([
      for k, v in var.listeners : contains(["http", "tcp"], v.protocol)
    ])
    error_message = "protocol doit être http ou tcp."
  }

  validation {
    condition = alltrue([
      for k, v in var.listeners :
      v.frontend_port >= 1 && v.frontend_port <= 65535
    ])
    error_message = "frontend_port doit être entre 1 et 65535."
  }

  validation {
    condition = alltrue(flatten([
      for lk, lv in var.listeners : [
        for bk, bv in lv.backends :
        (bv.container_id != null) != (bv.vm_instance_id != null)
      ]
    ]))
    error_message = "Chaque backend doit avoir exactement un de `container_id` ou `vm_instance_id`."
  }
}
