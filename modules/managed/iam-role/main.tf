locals {
  # XOR — exactly one of policy_document_json / statements must be set.
  has_json        = var.policy_document_json != null
  statements_list = var.statements == null ? [] : var.statements
  has_statements  = length(local.statements_list) > 0

  # Effective policy document JSON — either the user-provided raw string,
  # or the one composed by the `ccp_iam_policy_document` data source.
  policy_json = local.has_json ? var.policy_document_json : (
    length(data.ccp_iam_policy_document.this) > 0 ? data.ccp_iam_policy_document.this[0].json : null
  )
}

# Compose the policy document from `statements` when provided. Skipped when
# the caller passes `policy_document_json` directly.
data "ccp_iam_policy_document" "this" {
  provider = cetic-cloud-platform
  count    = local.has_statements ? 1 : 0

  dynamic "statement" {
    for_each = local.statements_list
    content {
      sid       = try(statement.value.sid, null)
      effect    = coalesce(try(statement.value.effect, null), "Allow")
      actions   = statement.value.actions
      resources = statement.value.resources

      dynamic "condition" {
        for_each = try(statement.value.conditions, [])
        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "ccp_iam_role" "this" {
  provider             = cetic-cloud-platform
  name                 = var.name
  description          = var.description
  policy_document_json = local.policy_json

  lifecycle {
    precondition {
      condition     = local.has_json != local.has_statements
      error_message = "Exactly one of `policy_document_json` or `statements` must be provided (XOR)."
    }
  }
}
