variable "tenant_id" {
  type        = string
  description = "UUID of the caller's tenant — used to build ARN patterns. Must match the tenant authenticated by the provider's API key (custom roles cannot reference foreign tenants)."
  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.tenant_id))
    error_message = "tenant_id must be a UUID v4."
  }
}

variable "region" {
  type        = string
  default     = "rnn"
  description = "Region segment used in registry ARNs (lowercase, e.g. `rnn`, `par`, `abj`)."
  validation {
    condition     = contains(["rnn", "par", "abj", "*"], var.region)
    error_message = "region must be one of: rnn, par, abj, or `*` for any region."
  }
}

variable "envs" {
  type        = list(string)
  default     = ["dev", "staging", "prod"]
  description = "List of environment names. For each env, a service account `ci-<env>` and a role `RegistryDeployer-<env>` are created. Registry ARN restriction = `registry/<env>-*`."
  validation {
    condition     = length(var.envs) >= 1 && length(var.envs) <= 10
    error_message = "envs must contain between 1 and 10 entries."
  }
  validation {
    condition     = alltrue([for e in var.envs : can(regex("^[a-z][a-z0-9-]{0,15}$", e))])
    error_message = "Each env must match ^[a-z][a-z0-9-]{0,15}$."
  }
}

variable "sa_expires_at" {
  type        = string
  default     = null
  description = "Optional RFC 3339 expiry timestamp applied to all per-env service accounts. `null` = no expiry."
}

variable "billing_viewer_member_id" {
  type        = string
  default     = null
  description = <<-EOT
    Optional UUID of an existing org member (`ccp_org_member.<name>.id`) to grant the cross-environment
    `BillingViewer` role to.

    When `null`, the BillingViewer role is created but no assignment is made — operators can attach
    it manually later via the console or by passing a member ID to this variable on a subsequent apply.
  EOT
}
