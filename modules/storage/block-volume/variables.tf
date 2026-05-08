variable "name" {
  type        = string
  description = "Nom du volume (1-100 chars, alphanum + `-` + `_`)."
}

variable "region" {
  type = string
  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "Région invalide."
  }
}

variable "size_gb" {
  type        = number
  description = "Taille en GB (1-16384). Mutable en place (resize up uniquement)."
  validation {
    condition     = var.size_gb >= 1 && var.size_gb <= 16384
    error_message = "size_gb doit être entre 1 et 16384."
  }
}

variable "attach_to" {
  type = object({
    id   = string
    type = string # "container" | "vm_instance"
  })
  default     = null
  description = "Cible d'attachement optionnelle. `null` = volume détaché. `type` doit être `container` ou `vm_instance`."

  validation {
    condition     = var.attach_to == null || contains(["container", "vm_instance"], try(var.attach_to.type, ""))
    error_message = "`attach_to.type` doit être `container` ou `vm_instance`."
  }
}

variable "tags" {
  type    = list(string)
  default = []
}
