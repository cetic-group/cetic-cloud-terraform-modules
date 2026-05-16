variable "org_prefix" {
  type        = string
  description = "Préfixe métier appliqué à toutes les ressources (3-32 chars, [a-z0-9-])."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}[a-z0-9]$", var.org_prefix))
    error_message = "`org_prefix` doit commencer par une lettre, ne contenir que [a-z0-9-], 3-32 chars, terminer par lettre/chiffre."
  }
}

variable "region" {
  type        = string
  description = "Région CETIC Cloud : `RNN`, `PAR` ou `ABJ`."

  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "La région doit être `RNN`, `PAR` ou `ABJ`."
  }
}

variable "ssh_public_key" {
  type        = string
  description = "Clé publique OpenSSH (`file(\"~/.ssh/id_ed25519.pub\")`)."
}

variable "hostname" {
  type        = string
  description = <<-EOT
    Hostname FQDN client servi par l'AppGW (validation ACME DNS-01).
    Un CNAME `hostname` → `<appgw>.app.cloud.cetic-group.com` doit être en place **avant** `terraform apply`,
    sinon l'émission du certificat échoue.
  EOT

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9.]{0,251}[a-z0-9])?$", var.hostname))
    error_message = "`hostname` doit être un FQDN valide en lowercase (RFC 1123)."
  }
}

variable "basic_auth_users" {
  type = list(object({
    user     = string
    password = string
  }))
  default     = null
  sensitive   = true
  description = <<-EOT
    Liste `{user, password}` activant le HTTP Basic Auth sur la route par défaut.
    `null` ou `[]` désactive l'auth. Les mots de passe sont **persistés en clair dans le state**
    (cf. doc atomic/appgw-route — utiliser un backend chiffré : S3+KMS, Vault, Terraform Cloud).
  EOT
}

# ── Application backend (container) ─────────────────────────────────────────

variable "app_plan" {
  type        = string
  default     = "small"
  description = "Plan d'instance du container backend : `nano`/`micro`/`small`/`medium`/`large`/`xlarge`."
}

variable "app_template" {
  type        = string
  default     = "ubuntu-24.04"
  description = "Template OS du container (clé du catalogue, voir `data.ccp_lxc_templates`)."
}

variable "app_root_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe root injecté sur le container à la création (8-128 chars)."

  validation {
    condition     = length(var.app_root_password) >= 8 && length(var.app_root_password) <= 128
    error_message = "`app_root_password` doit faire entre 8 et 128 caractères."
  }
}

variable "app_listen_port" {
  type        = number
  default     = 8080
  description = "Port d'écoute de l'app sur le container — envoyé en `port` au target group."
}

variable "app_health_path" {
  type        = string
  default     = "/"
  description = "Path HTTP du health check L7."
}

# ── AppGW config ────────────────────────────────────────────────────────────

variable "appgw_plan" {
  type        = string
  default     = "small"
  description = "Plan de l'AppGW : `small` / `medium` / `large`."

  validation {
    condition     = contains(["small", "medium", "large"], var.appgw_plan)
    error_message = "`appgw_plan` doit être `small`, `medium` ou `large`."
  }
}

variable "waf_preset" {
  type        = string
  default     = "permissive"
  description = "Preset WAF appliqué à la route par défaut : `off` / `permissive` / `strict`."

  validation {
    condition     = contains(["off", "permissive", "strict"], var.waf_preset)
    error_message = "`waf_preset` doit être `off`, `permissive` ou `strict`."
  }
}

variable "tags_extra" {
  type        = list(string)
  default     = []
  description = "Tags additionnels propagés à toutes les ressources créées."
}
