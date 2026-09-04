variable "name" {
  type        = string
  description = <<-EOT
    Nom de la zone, ex. `corp.internal`. Un suffixe interne (`.internal`,
    `.lan`, `.home.arpa`, ou une étiquette unique comme `corp`) est l'usage
    principal du produit et ne demande aucune preuve.

    Un **domaine public** (`exemple.com`) exige de prouver qu'on le possède :
    la zone naît alors en attente, et `ownership_challenge` dit quoi publier.
    Voir `wait_for_verification`.
  EOT

  validation {
    condition     = length(var.name) > 0 && length(var.name) <= 253
    error_message = "name doit faire 1 à 253 caractères."
  }
}

variable "vpc_id" {
  type        = string
  description = <<-EOT
    UUID du **réseau privé** servi par la zone — pas d'un de ses sous-réseaux.
    Le serveur de noms pose une adresse dans chaque sous-réseau du réseau et y
    répond les mêmes zones.

    Un réseau de plus de neuf sous-réseaux ne peut pas être servi : la création
    est refusée plutôt que de laisser une partie des machines sans résolution.
  EOT
}

variable "tier" {
  type        = string
  default     = null
  description = <<-EOT
    Niveau de service du serveur de noms : `dev` (un serveur) ou `prod`
    (serveur redondant avec bascule automatique). `null` laisse le défaut de la
    plateforme (`dev`).

    ⚠️ **C'est une propriété du RÉSEAU, pas de la zone.** Toutes les zones d'un
    même `vpc_id` partagent leur serveur, donc son niveau : en demander un autre
    est refusé, et le message nomme celui déjà en place.
  EOT

  validation {
    condition     = var.tier == null || contains(["dev", "prod"], coalesce(var.tier, "dev"))
    error_message = "tier doit valoir dev ou prod."
  }
}

variable "default_ttl" {
  type        = number
  default     = null
  description = <<-EOT
    Durée de vie par défaut de la zone, en secondes (60 à 604800). `null`
    laisse le réglage de la plateforme (3600 s) — le préciser ici le figerait.
  EOT

  validation {
    condition     = var.default_ttl == null || (coalesce(var.default_ttl, 3600) >= 60 && coalesce(var.default_ttl, 3600) <= 604800)
    error_message = "default_ttl doit être compris entre 60 et 604800 secondes."
  }
}

variable "dnssec_enabled" {
  type        = bool
  default     = false
  description = <<-EOT
    Signe la zone. Sur une zone privée, DNSSEC ne protège de presque rien : il
    n'y a aucune chaîne de confiance depuis la racine publique.
  EOT
}

variable "wait_for_verification" {
  type        = bool
  default     = false
  description = <<-EOT
    N'a de sens que pour un **domaine public**.

    `false` (défaut) : l'apply rend la main tout de suite, avec dans
    `ownership_challenge` l'enregistrement `TXT` à publier dans le DNS public du
    domaine. `true` : l'apply demande à la plateforme de contrôler la preuve et
    attend que la zone soit servie.

    Le parcours normal est donc **deux apply** : le premier rend
    l'enregistrement, le second — une fois publié — active la zone.
  EOT
}

variable "records" {
  type = map(object({
    name    = string
    type    = string
    ttl     = optional(number)
    records = set(string)
  }))
  default     = {}
  description = <<-EOT
    Les enregistrements de la zone, indexés par une clé stable de votre choix.
    La clé n'est qu'une étiquette Terraform : c'est le couple (`name`, `type`)
    qui identifie l'enregistrement côté plateforme.

    - `name` : relatif (`www`), absolu (`www.corp.internal`), ou `@` pour la
      zone elle-même ;
    - `type` : `A`, `AAAA`, `CNAME`, `MX`, `TXT`, `SRV` ou `CAA`. Pas de `NS` —
      celui de l'apex est posé par la plateforme, ailleurs c'est une délégation
      qu'une zone privée refuse ;
    - `records` : 1 à 32 valeurs dans leur syntaxe de présentation
      (`10 mail.corp.internal.` pour un MX, `"v=spf1 -all"` guillemets compris
      pour un TXT). **L'ensemble REMPLACE** : chaque apply envoie la liste
      entière, une valeur retirée cesse d'être répondue ;
    - `ttl` : 60 à 604800 secondes, `null` = 3600.

    ```hcl
    records = {
      www     = { name = "www", type = "A", records = ["10.20.0.10"], ttl = 300 }
      apex_mx = { name = "@", type = "MX", records = ["10 mail.corp.internal."] }
    }
    ```
  EOT

  validation {
    condition = alltrue([
      for r in values(var.records) :
      contains(["A", "AAAA", "CNAME", "MX", "TXT", "SRV", "CAA"], r.type)
    ])
    error_message = "type doit valoir A, AAAA, CNAME, MX, TXT, SRV ou CAA. NS n'est pas éditable sur une zone privée."
  }

  validation {
    condition = alltrue([
      for r in values(var.records) : length(r.records) >= 1 && length(r.records) <= 32
    ])
    error_message = "Chaque enregistrement doit porter de 1 à 32 valeurs."
  }

  validation {
    condition = alltrue([
      for r in values(var.records) :
      r.ttl == null || (coalesce(r.ttl, 3600) >= 60 && coalesce(r.ttl, 3600) <= 604800)
    ])
    error_message = "ttl doit être compris entre 60 et 604800 secondes."
  }
}
