variable "name" {
  type        = string
  description = "Nom du bucket S3 (DNS-compatible : 3-63 chars, [a-z0-9-], commence/finit par alphanum)."
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "Nom de bucket invalide (S3 DNS rules)."
  }
}

variable "region" {
  type = string
  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "Région invalide."
  }
}

variable "is_public" {
  type        = bool
  default     = false
  description = "Si `true`, le bucket policy autorise un accès anonyme en lecture (assets publics)."
}

variable "scoped_keys" {
  description = <<-EOT
    Map de clés S3 scopées à créer. Clé = label logique.

    Niveaux d'accès : `read` / `write` / `readwrite` / `full`.
    Les credentials sont sortis dans `output.scoped_keys` (sensitive).
  EOT
  type = map(object({
    access_level = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.scoped_keys : contains(["read", "write", "readwrite", "full"], v.access_level)
    ])
    error_message = "access_level doit être l'un de : read, write, readwrite, full."
  }
}

variable "tags" {
  type    = list(string)
  default = []
}

variable "cors_rules" {
  description = <<-EOT
    Règles CORS du bucket (liste ordonnée). Vide par défaut : CORS n'est alors
    pas géré par ce module et une configuration existante est laissée telle quelle.

    Chaque règle : `allowed_origins` (obligatoire), `allowed_methods`
    (obligatoire : GET, PUT, POST, DELETE, HEAD), `allowed_headers`,
    `expose_headers`, `max_age_seconds` (défaut 3600), `description`.
  EOT
  type = list(object({
    allowed_origins = set(string)
    allowed_methods = set(string)
    allowed_headers = optional(set(string))
    expose_headers  = optional(set(string))
    max_age_seconds = optional(number)
    description     = optional(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for r in var.cors_rules :
      length(r.allowed_origins) > 0 && length(r.allowed_methods) > 0
    ])
    error_message = "Chaque règle CORS doit avoir au moins une origine et une méthode."
  }

  validation {
    condition = alltrue([
      for r in var.cors_rules :
      alltrue([for m in r.allowed_methods : contains(["GET", "PUT", "POST", "DELETE", "HEAD"], m)])
    ])
    error_message = "Méthodes CORS permises : GET, PUT, POST, DELETE, HEAD."
  }
}

variable "versioning" {
  description = <<-EOT
    Versionnage du bucket. `null` par défaut : le versionnage n'est alors pas
    géré par ce module et un réglage existant (console, CLI) est laissé tel quel.

    - `status` : `Enabled` ou `Suspended`. Jamais « désactivé » : S3 ne revient
      pas à « jamais versionné ». Un nouveau bucket ne peut pas être créé
      `Suspended` (le provider le refuse au plan).
    - `noncurrent_version_expiration_days` : conservation des versions
      anciennes, 1 à 3650 jours. Absente, elle n'est pas envoyée et la valeur
      en place est gardée (30 jours pour un bucket jamais versionné). La
      raccourcir efface plus tôt les versions anciennes.

    ⚠️ Sur un bucket déjà versionné hors plateforme (client S3), les versions
    anciennes sont souvent gardées sans limite : la première prise en charge
    pose cette durée, 30 jours par défaut, et efface les versions plus
    anciennes. Le plan du provider l'annonce par un avertissement.

    Repasser à `null` arrête la gestion sans désactiver le versionnage.
  EOT
  type = object({
    status                             = string
    noncurrent_version_expiration_days = optional(number)
  })
  default = null

  validation {
    condition     = var.versioning == null ? true : contains(["Enabled", "Suspended"], var.versioning.status)
    error_message = "versioning.status doit être « Enabled » ou « Suspended » (le versionnage ne se désactive pas, il se suspend)."
  }

  validation {
    condition = var.versioning == null ? true : (
      var.versioning.noncurrent_version_expiration_days == null ? true : (
        floor(var.versioning.noncurrent_version_expiration_days) == var.versioning.noncurrent_version_expiration_days &&
        var.versioning.noncurrent_version_expiration_days >= 1 &&
        var.versioning.noncurrent_version_expiration_days <= 3650
      )
    )
    error_message = "versioning.noncurrent_version_expiration_days doit être un nombre entier de jours entre 1 et 3650."
  }
}

variable "encryption_mode" {
  description = <<-EOT
    Encryption mode of the bucket. `none` by default (no customer-supplied key).

    - Chosen at creation and not changeable: changing it replaces the bucket
      and deletes all its files. Copy them first.
    - `sse_c`: the encryption key is supplied by you on every read and write
      request. CETIC never knows it and cannot recover it: a lost key means
      the files are lost for good. Such a bucket is always private
      (`is_public` must stay `false`).
  EOT
  type        = string
  default     = "none"

  validation {
    condition     = can(regex("^[a-z][a-z0-9_]*$", var.encryption_mode))
    error_message = "encryption_mode must start with a lowercase letter and contain only lowercase letters, digits and underscores (e.g. \"none\", \"sse_c\")."
  }
}
