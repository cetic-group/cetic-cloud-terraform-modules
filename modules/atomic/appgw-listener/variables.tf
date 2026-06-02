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

variable "acme_challenge" {
  type        = string
  default     = null
  description = <<-EOT
    Type de challenge ACME (Let's Encrypt) pour émettre le certificat TLS du listener :
    `http01` ou `dns01`. **Sans cet attribut, aucun certificat TLS n'est jamais émis.**

    `dns01` requiert en plus `acme_dns_provider` + `acme_dns_credentials`.

    **Immutable** : un changement force destroy + create.
  EOT

  validation {
    condition     = var.acme_challenge == null ? true : contains(["http01", "dns01"], var.acme_challenge)
    error_message = "`acme_challenge` doit être `http01`, `dns01` ou null."
  }
}

variable "acme_dns_provider" {
  type        = string
  default     = null
  description = <<-EOT
    Clé du provider DNS pour le challenge `dns01` (ex. `cloudflare`, `route53`).
    Requis quand `acme_challenge = "dns01"`. Découvrir le catalogue supporté via la
    data source `ccp_acme_dns_providers`.

    **Immutable** : un changement force destroy + create.
  EOT
}

variable "acme_dns_credentials" {
  type        = map(string)
  default     = null
  sensitive   = true
  description = <<-EOT
    Credentials du provider DNS pour le challenge `dns01` (write-only — jamais relus par l'API).
    Les clés attendues dépendent du provider (cf. `ccp_acme_dns_providers`).
    Requis quand `acme_challenge = "dns01"`.

    **Immutable** : un changement force destroy + create.
  EOT
}
