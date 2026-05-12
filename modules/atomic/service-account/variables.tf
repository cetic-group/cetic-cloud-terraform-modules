variable "name" {
  type        = string
  description = "Human-readable name of the service account (1-64 chars), unique within the tenant."
  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 64
    error_message = "name must be 1 to 64 characters."
  }
}

variable "description" {
  type        = string
  default     = null
  description = "Free-form description (max 512 chars)."
  validation {
    condition     = var.description == null || length(coalesce(var.description, "")) <= 512
    error_message = "description must be at most 512 characters."
  }
}

variable "expires_at" {
  type        = string
  default     = null
  description = "Optional RFC 3339 expiry timestamp. After this date the SA token is rejected by the API."
}
