variable "name" {
  type        = string
  description = "DNS-friendly secret name (1-63 chars, lowercase alphanum + dash, must start with a letter), unique within the org."
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.name))
    error_message = "name must match ^[a-z][a-z0-9-]{0,62}$ (DNS-friendly: starts with a lowercase letter, lowercase alphanumerics and dashes only, max 63 chars)."
  }
}

variable "description" {
  type        = string
  default     = null
  description = "Free-form description (max 500 chars)."
  validation {
    condition     = var.description == null || length(coalesce(var.description, "")) <= 500
    error_message = "description must be at most 500 characters."
  }
}

variable "data" {
  type        = map(string)
  description = "Map of plaintext key/value pairs to encrypt and store. Sensitive — persisted in the Terraform state. Changing triggers a server-side rotation."
  sensitive   = true
  validation {
    condition     = length(var.data) >= 1
    error_message = "data must contain at least one key/value pair."
  }
}

variable "tags" {
  type        = list(string)
  default     = []
  description = "Free-form list of tags for organising the secret (e.g. [\"env:prod\", \"team:platform\"]). Mutable in place."
}
