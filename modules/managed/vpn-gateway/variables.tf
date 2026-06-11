# ── Gateway core ──────────────────────────────────────────────────────────────

variable "name" {
  description = "Nom de base de la passerelle d'accès VPN privé (1–100 chars)."
  type        = string
  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 100
    error_message = "`name` doit faire entre 1 et 100 caractères."
  }
}

variable "region" {
  description = "Région CETIC Cloud : `RNN` / `PAR` / `ABJ`. Force replacement."
  type        = string
  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "La région doit être `RNN`, `PAR` ou `ABJ`."
  }
}

variable "plan" {
  description = "Plan de la passerelle : `small` (défaut) / `medium` / `large`."
  type        = string
  default     = "small"
  validation {
    condition     = contains(["small", "medium", "large"], var.plan)
    error_message = "`plan` doit être l'un de : small, medium, large."
  }
}

# Deux façons de rattacher la passerelle à un ou plusieurs VPC. Fournissez
# `vpc_ids` (un ou plusieurs VPC à exposer) OU `vpc_id` (raccourci pour un seul).
variable "vpc_ids" {
  description = <<-EOT
    Liste des UUID de VPC dont les ressources privées sont joignables à travers
    le VPN. Au moins un VPC est requis. Utilisez `vpc_id` à la place pour un VPC unique.
  EOT
  type        = list(string)
  default     = null
}

variable "vpc_id" {
  description = "Raccourci pour un seul VPC. Ignoré si `vpc_ids` est fourni."
  type        = string
  default     = null
}

variable "public_ip_id" {
  description = "UUID d'une IP publique à attacher comme point d'entrée du VPN. `null` = la plateforme alloue automatiquement un point d'entrée public."
  type        = string
  default     = null
}

variable "peer_pool_cidr" {
  description = <<-EOT
    Plage CIDR privée allouée aux clients VPN connectés (ex. `10.99.0.0/24`).
    `null` = la plateforme choisit une plage par défaut hors-conflit.
  EOT
  type        = string
  default     = null
  validation {
    condition     = var.peer_pool_cidr == null ? true : can(cidrhost(var.peer_pool_cidr, 0))
    error_message = "`peer_pool_cidr` doit être un CIDR IPv4 valide (ex. 10.99.0.0/24)."
  }
}

variable "dns" {
  description = "Liste de serveurs DNS poussés aux clients VPN. `[]` = pas de DNS poussé (le client garde sa config)."
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for s in var.dns : can(cidrhost("${s}/32", 0))])
    error_message = "Chaque entrée de `dns` doit être une adresse IPv4 valide."
  }
}

variable "tags" {
  description = "Tags free-form (max 60, max 50 chars chacun)."
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.tags) <= 60
    error_message = "`tags` peut contenir au plus 60 entrées."
  }
  validation {
    condition     = alltrue([for t in var.tags : length(t) <= 50])
    error_message = "Chaque tag doit faire au plus 50 caractères."
  }
}

# ── Peers (clients VPN) ─────────────────────────────────────────────────────────

variable "peers" {
  description = <<-EOT
    Map des peers VPN à enregistrer sur la passerelle. Clé = label logique
    (utilisé comme nom du peer si `name` est omis).

    Deux **types** de peer (`peer_type`) :

    - **`client`** (défaut) : un appareil unique nomade (poste, téléphone, …)
      qui se connecte et se voit assigner une seule adresse privée. Laissez
      `site_cidrs` vide.
    - **`site`** : un site distant (routeur/passerelle d'un réseau distant) qui
      termine un tunnel **site-à-site**. Listez les sous-réseaux distants
      joignables via `site_cidrs` (obligatoire, au moins une entrée).

    Deux modèles d'enrôlement (orthogonaux au type) :

    - **Clé fournie par le client** : renseignez `public_key`. Aucune clé privée
      ne transite par la plateforme ni par le state Terraform (recommandé).
    - **Clé générée par la plateforme** : mettez `managed = true` (et omettez
      `public_key`). La plateforme génère le couple de clés et retourne une
      configuration prête à l'emploi. Avec `store_private_key = false` la config
      n'est récupérable qu'une seule fois (sinon elle est stockée dans le state) ;
      `one_time = true` invalide la config après la première récupération.

    Champs :
    - `name`               : nom affiché du peer (défaut = clé de la map)
    - `peer_type`          : `client` (défaut) ou `site` (site-à-site)
    - `site_cidrs`         : sous-réseaux distants joignables (obligatoire si `peer_type = site`)
    - `public_key`         : clé publique du client (modèle « clé fournie »)
    - `managed`            : la plateforme génère le couple de clés (modèle « clé générée »)
    - `store_private_key`  : stocke la config générée dans le state (modèle « clé générée »)
    - `one_time`           : config à usage unique (modèle « clé générée »)
  EOT
  type = map(object({
    name              = optional(string)
    peer_type         = optional(string, "client")
    site_cidrs        = optional(list(string), [])
    public_key        = optional(string)
    managed           = optional(bool, false)
    store_private_key = optional(bool, false)
    one_time          = optional(bool, false)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, p in var.peers : (p.public_key != null) != p.managed
    ])
    error_message = "Chaque peer doit fournir SOIT `public_key` (clé fournie par le client) SOIT `managed = true` (clé générée par la plateforme), jamais les deux ni aucun."
  }

  validation {
    condition = alltrue([
      for k, p in var.peers : contains(["client", "site"], p.peer_type)
    ])
    error_message = "`peer_type` doit être `client` ou `site`."
  }

  validation {
    # site → site_cidrs non vide ; client → site_cidrs vide.
    condition = alltrue([
      for k, p in var.peers :
      p.peer_type == "site" ? length(p.site_cidrs) >= 1 : length(p.site_cidrs) == 0
    ])
    error_message = "Un peer `site` doit fournir au moins un `site_cidrs` (tunnel site-à-site) ; un peer `client` ne doit pas définir `site_cidrs`."
  }

  validation {
    condition = alltrue(flatten([
      for k, p in var.peers : [
        for c in p.site_cidrs : can(cidrhost(c, 0))
      ]
    ]))
    error_message = "Chaque entrée de `site_cidrs` doit être un CIDR IPv4 valide (ex. 192.168.50.0/24)."
  }
}
