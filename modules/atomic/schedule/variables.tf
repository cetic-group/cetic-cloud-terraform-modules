variable "name" {
  type        = string
  description = "Label lisible du planning, unique dans l'org (1-63 caractères). Mutable in-place."
  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 63
    error_message = "name doit faire entre 1 et 63 caractères."
  }
}

variable "resource_type" {
  type        = string
  description = <<-EOT
    Type de ressource piloté par le planning : `vm`, `container`, `vm_scale_set`,
    `container_scale_set`, `ccks_node_pool` (un pool de nodes individuel, PAS le
    cluster entier) ou `db_instance`. **Immuable** : le changer force un
    remplacement (destroy + create).
  EOT
  validation {
    condition = contains(
      ["vm", "container", "vm_scale_set", "container_scale_set", "ccks_node_pool", "db_instance"],
      var.resource_type,
    )
    error_message = "resource_type doit être l'un de : vm, container, vm_scale_set, container_scale_set, ccks_node_pool, db_instance."
  }
}

variable "resource_id" {
  type        = string
  description = <<-EOT
    UUID de la ressource cible. Pour `ccks_node_pool` c'est l'id du pool de nodes
    (`ccp_k8s_node_pool.id`), pas l'id du cluster. **Immuable** : le changer force
    un remplacement.
  EOT
  validation {
    condition     = length(var.resource_id) > 0
    error_message = "resource_id ne peut pas être vide."
  }
}

variable "timezone" {
  type        = string
  default     = "Europe/Paris"
  description = "Timezone IANA d'interprétation des fenêtres (ex. `Europe/Paris`, `Africa/Abidjan`). Défaut `Europe/Paris`. Mutable in-place."
  validation {
    condition     = length(var.timezone) > 0
    error_message = "timezone ne peut pas être vide (fournir une timezone IANA, ex. `Europe/Paris`)."
  }
}

variable "enabled" {
  type        = bool
  default     = true
  description = "Le planning pilote-t-il activement la cible. À `false`, le planning est conservé mais jamais appliqué (la cible reste dans son état courant). Défaut `true`. Mutable in-place."
}

variable "windows" {
  type = list(object({
    start_day  = number
    start_hour = number
    end_day    = number
    end_hour   = number
  }))
  description = <<-EOT
    Liste d'une ou plusieurs **fenêtres OFF hebdomadaires**. La cible est éteinte
    pendant chaque intervalle `[start → end)` (fin exclue) et allumée en dehors.
    Quand la fin est plus tôt dans la semaine que le début, l'intervalle enjambe
    le week-end. Exemple : `{ start_day = 4, start_hour = 20, end_day = 0, end_hour = 8 }`
    éteint du vendredi 20:00 au lundi 08:00.

    - `start_day` / `end_day` : jour, `0`=Lundi … `6`=Dimanche.
    - `start_hour` / `end_hour` : heure pleine, `0..24` (`HH:00`).

    La plateforme refuse (422) les fenêtres < 1h, les écarts < 1h, les fenêtres qui
    se chevauchent ou plus de deux cycles marche/arrêt par jour.
  EOT

  validation {
    condition     = length(var.windows) >= 1
    error_message = "windows doit contenir au moins une fenêtre."
  }
  validation {
    condition     = alltrue([for w in var.windows : w.start_day >= 0 && w.start_day <= 6])
    error_message = "Chaque windows[*].start_day doit être compris entre 0 (Lundi) et 6 (Dimanche)."
  }
  validation {
    condition     = alltrue([for w in var.windows : w.end_day >= 0 && w.end_day <= 6])
    error_message = "Chaque windows[*].end_day doit être compris entre 0 (Lundi) et 6 (Dimanche)."
  }
  validation {
    condition     = alltrue([for w in var.windows : w.start_hour >= 0 && w.start_hour <= 24])
    error_message = "Chaque windows[*].start_hour doit être compris entre 0 et 24 (heure pleine)."
  }
  validation {
    condition     = alltrue([for w in var.windows : w.end_hour >= 0 && w.end_hour <= 24])
    error_message = "Chaque windows[*].end_hour doit être compris entre 0 et 24 (heure pleine)."
  }
  validation {
    condition     = alltrue([for w in var.windows : floor(w.start_hour) == w.start_hour && floor(w.end_hour) == w.end_hour])
    error_message = "Les heures des fenêtres doivent être des heures pleines (entiers, HH:00)."
  }
}
