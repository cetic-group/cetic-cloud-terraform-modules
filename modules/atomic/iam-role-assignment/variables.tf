variable "role_id" {
  type        = string
  description = "UUID of the IAM role to attach. Forces replacement when changed."
}

variable "principal_type" {
  type        = string
  description = "Principal type: `org_member`, `api_key`, `service_account`, or `ccks_workload`. Forces replacement."
  validation {
    condition     = contains(["org_member", "api_key", "service_account", "ccks_workload"], var.principal_type)
    error_message = "principal_type must be one of: org_member, api_key, service_account, ccks_workload."
  }
}

variable "principal_id" {
  type        = string
  description = "UUID of the principal (org member ID, API key ID, service account ID, or CCKS cluster ID). Forces replacement."
}

variable "expires_at" {
  type        = string
  default     = null
  description = "Optional RFC 3339 expiry timestamp. After expiry, the assignment is ignored during policy evaluation. Forces replacement."
}
