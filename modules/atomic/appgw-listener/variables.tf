variable "appgw_id" {
  type        = string
  description = "UUID de l'Application Gateway parente. **Immutable** : un changement force destroy + create du listener."
}

variable "hostname" {
  type        = string
  description = <<-EOT
    Hostname FQDN servi par ce listener (ex. `api.example.com` ou un sous-domaine auto
    `acme-rnn-01.app.cloud.cetic-group.com`). Lowercase, RFC 1123, max 253 chars.

    **Immutable** : renommer un hostname force destroy + create (sinon vieux certs orphelins).
  EOT

  validation {
    condition     = can(regex("^[a-z0-9]([-a-z0-9.]{0,251}[a-z0-9])?$", var.hostname))
    error_message = "`hostname` doit être un FQDN valide en lowercase (RFC 1123, max 253 chars)."
  }
}

variable "custom_domain" {
  type        = bool
  default     = false
  description = <<-EOT
    `true` = le hostname est un domaine appartenant au client (validation ACME DNS-01,
    CNAME requis vers la gateway **avant** apply, sinon l'émission échoue).
    `false` (défaut) = sous-domaine auto sous `app.cloud.cetic-group.com` (validation ACME HTTP-01).

    **Immutable** : changer ce mode force destroy + create.
  EOT
}
