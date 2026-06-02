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

variable "plan" {
  type        = string
  default     = "small"
  description = <<-EOT
    Plan de capacité du LB. Détermine la taille de la paire d'instances LB :
    - `small`  (défaut) — 1 vCPU / 512 Mo —  4,99 €/mois.
    - `medium`          — 2 vCPU /   1 Go — 11,99 €/mois.
    - `large`           — 4 vCPU /   2 Go — 27,99 €/mois.

    **Immuable** : changer de plan plus tard force un remplacement du LB
    (le provider porte `RequiresReplace` sur cet attribut — pas de
    redimensionnement en place).
  EOT

  validation {
    condition     = contains(["small", "medium", "large"], var.plan)
    error_message = "`plan` doit être l'un de : small, medium, large."
  }
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
    Map de listeners à exposer. La clé est un **label purement logique**
    (lisibilité du HCL / indexation) — elle n'est PAS envoyée à l'API.

    Champs (alignés sur le schéma `ccp_load_balancer.listener` du provider) :
    - `protocol` : `tcp` | `http` | `https` (défaut `tcp`). **Immuable**.
    - `listen_port` : port d'écoute du LB (1-65535). **Immuable**.
    - `algorithm` : `roundrobin` | `leastconn` | `source` (défaut `roundrobin`). **Immuable**.
    - `health_check_enabled` : active les health checks backend (défaut `true`).
    - `health_check_path` : chemin HTTP des health checks (`http`/`https`).
    - `domain` : FQDN servi par un listener `https`. Requis si `acme_challenge` set. Lowercase.
    - `acme_challenge` : `http01` | `dns01` — émission auto d'un cert Let's Encrypt.
        Requiert `protocol = "https"` + `domain`. `dns01` requiert en plus
        `acme_dns_provider` + `acme_dns_credentials`.
    - `acme_dns_provider` : clé du provider DNS pour `dns01` (ex. `cloudflare`).
    - `acme_dns_credentials` : credentials DNS pour `dns01` (sensible, write-only).
    - `backends` : map de backends. Chaque clé = label logique. Valeur :
        - `container_id` (XOR) `vm_instance_id` : UUID du backend.
        - `port` : port destination sur le backend.
        - `weight` : optionnel, défaut 1 (réconcilié en place).
  EOT

  type = map(object({
    protocol             = optional(string, "tcp")
    listen_port          = number
    algorithm            = optional(string, "roundrobin")
    health_check_enabled = optional(bool, true)
    health_check_path    = optional(string)
    domain               = optional(string)
    acme_challenge       = optional(string)
    acme_dns_provider    = optional(string)
    acme_dns_credentials = optional(map(string))
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
      for k, v in var.listeners : contains(["tcp", "http", "https"], v.protocol)
    ])
    error_message = "protocol doit être tcp, http ou https."
  }

  validation {
    condition = alltrue([
      for k, v in var.listeners : contains(["roundrobin", "leastconn", "source"], v.algorithm)
    ])
    error_message = "algorithm doit être roundrobin, leastconn ou source."
  }

  validation {
    condition = alltrue([
      for k, v in var.listeners :
      v.listen_port >= 1 && v.listen_port <= 65535
    ])
    error_message = "listen_port doit être entre 1 et 65535."
  }

  validation {
    condition = alltrue([
      for k, v in var.listeners :
      v.acme_challenge == null ? true : contains(["http01", "dns01"], v.acme_challenge)
    ])
    error_message = "acme_challenge doit être http01 ou dns01 (ou null)."
  }

  validation {
    condition = alltrue([
      for k, v in var.listeners :
      v.acme_challenge == null || (v.protocol == "https" && v.domain != null)
    ])
    error_message = "acme_challenge requiert protocol = \"https\" et un domain non-null."
  }

  validation {
    condition = alltrue([
      for k, v in var.listeners :
      v.acme_challenge != "dns01" || (v.acme_dns_provider != null && v.acme_dns_credentials != null)
    ])
    error_message = "acme_challenge = \"dns01\" requiert acme_dns_provider et acme_dns_credentials."
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
