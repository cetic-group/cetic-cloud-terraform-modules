variable "name" {
  description = "Human-readable name (1-64 chars), unique within the tenant."
  type        = string
  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 64
    error_message = "name must be 1 to 64 characters."
  }
}

variable "description" {
  description = "Free-form description of the role (max 512 chars)."
  type        = string
  default     = null
  validation {
    condition     = length(var.description != null ? var.description : "") <= 512
    error_message = "description must be at most 512 characters."
  }
}

variable "policy_document_json" {
  description = <<-EOT
    Raw JSON PolicyDocument string (AWS IAM-style — `{ "version": "2026-05-10", "statements": [...] }`).

    Mutually exclusive with `statements`. Use this attribute when you author the document
    out-of-band (e.g. from a `file()` call, a `jsonencode(...)` block, or another data
    source). Use `statements` for the ergonomic HCL composition path.
  EOT
  type        = string
  default     = null
}

variable "statements" {
  description = <<-EOT
    List of policy statement blocks composed into a PolicyDocument via the
    `ccp_iam_policy_document` data source. Mutually exclusive with `policy_document_json`.

    Each statement:
      - `effect`    : `"Allow"` (default) or `"Deny"`.
      - `actions`   : non-empty list, e.g. `["registry:Push", "registry:Pull"]`. Wildcards allowed.
      - `resources` : non-empty list of ARN patterns, e.g. `["arn:ccp:registry:rnn:T:registry/myreg*"]`.
      - `sid`       : optional short label.
      - `conditions`: optional list of condition tuples `{ test, variable, values }`.

    v1 condition operators: `StringEquals`, `StringNotEquals`, `StringLike`,
    `IpAddress`, `NotIpAddress`, `DateGreaterThan`, `DateLessThan`. v1 condition
    keys: `SourceIp`, `RequestTime`, `RequestRegion`, `ResourceTag`,
    `RequestTag`, `OrgId`, `ApiKeyPrefix`, `PrincipalType`.
  EOT
  type = list(object({
    sid       = optional(string)
    effect    = optional(string, "Allow")
    actions   = list(string)
    resources = list(string)
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }))
  default = null

  validation {
    condition = var.statements == null ? true : alltrue([
      for s in var.statements : contains(["Allow", "Deny"], coalesce(s.effect, "Allow"))
    ])
    error_message = "Each statement.effect must be either \"Allow\" or \"Deny\"."
  }

  validation {
    condition = var.statements == null ? true : alltrue([
      for s in var.statements : length(s.actions) > 0
    ])
    error_message = "Each statement must declare at least one action."
  }

  validation {
    condition = var.statements == null ? true : alltrue([
      for s in var.statements : length(s.resources) > 0
    ])
    error_message = "Each statement must declare at least one resource ARN pattern."
  }
}
