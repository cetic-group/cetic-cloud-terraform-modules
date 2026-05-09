variable "name" {
  type        = string
  description = "Nom du VPC."

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 64
    error_message = "Le nom du VPC doit faire entre 1 et 64 caractères."
  }
}

variable "region" {
  type        = string
  description = "Région du VPC : `RNN` (Rennes), `PAR` (Paris) ou `ABJ` (Abidjan)."

  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "La région doit être l'une de : RNN, PAR, ABJ."
  }
}

variable "tags" {
  type        = list(string)
  default     = []
  description = "Tags libres (max 60, max 50 chars chacun)."
}

variable "vnets" {
  description = <<-EOT
    Map de VNets à créer dans le VPC. Clé = nom logique (immutable, sert de ref interne).

    Champs par VNet :
    - `cidr` : bloc CIDR (`10.0.1.0/24`). Immutable.
    - `name` : nom affiché côté CETIC Cloud (par défaut = clé de la map).
    - `snat` : si `true`, SNAT/MASQUERADE outbound activé. Défaut `true`.
    - `isolated` : si `true`, le firewall global du VNet est ON (DROP par
      défaut sur le trafic inter-VNet). Sans isolation, les
      `firewall_rules` sont définies mais inactives. Défaut `false`.
    - `tags` : tags VNet.
    - `ip_reservations` : map de réservations IP (clé = nom logique, valeur = { ip, range_end?, description? }).
    - `firewall_rules` : liste de règles firewall ACCEPT (positions auto = 10, 20, 30…).

    Voir `examples/quickstart-container/` pour un exemple minimal.
  EOT

  type = map(object({
    cidr     = string
    name     = optional(string)
    snat     = optional(bool, true)
    isolated = optional(bool, false)
    tags     = optional(list(string), [])
    ip_reservations = optional(map(object({
      ip          = string
      range_end   = optional(string)
      description = optional(string)
    })), {})
    firewall_rules = optional(list(object({
      direction   = string                  # "in" | "out" | "forward" (case-insensitive)
      protocol    = optional(string, "tcp") # "tcp" | "udp" | "icmp"
      source_cidr = optional(string)
      dest_cidr   = optional(string)
      port        = optional(string) # "80" ou "8000-9000"
      description = optional(string)
    })), [])
  }))
  default = {}

  validation {
    condition     = alltrue([for k, v in var.vnets : can(cidrhost(v.cidr, 0))])
    error_message = "Chaque `vnets[*].cidr` doit être un CIDR valide (ex. `10.0.1.0/24`)."
  }
}

# `peering_accepter_vpc_ids` retiré en v0.3.0 — le concept VPC-level peering
# n'existe pas backend. Utiliser `modules/network/vnet-peering` directement
# pour peer 2 VNets (intra-VPC ou inter-VPC).
