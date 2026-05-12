variable "name" {
  type        = string
  description = "Human-readable name of the IAM role (1-64 chars), unique within the tenant."
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

variable "policy_document_json" {
  type        = string
  description = <<-EOT
    PolicyDocument as a raw JSON string (AWS IAM-style — version + statements).

    Compose ergonomically using `data "ccp_iam_policy_document"` if you prefer HCL.
  EOT
}
