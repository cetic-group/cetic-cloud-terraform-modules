mock_provider "ccp" {
  mock_resource "ccp_iam_role" {
    defaults = {
      id                   = "00000000-0000-0000-0000-000000000010"
      policy_hash          = "abc123def456"
      is_built_in          = false
      created_at           = "2026-05-12T00:00:00Z"
      updated_at           = "2026-05-12T00:00:00Z"
      policy_document_json = "{\"statements\":[{\"actions\":[\"registry:*\"],\"effect\":\"Allow\",\"resources\":[\"*\"]}],\"version\":\"2026-05-10\"}"
    }
  }

  mock_data "ccp_iam_policy_document" {
    defaults = {
      json        = "{\"statements\":[{\"actions\":[\"registry:*\"],\"effect\":\"Allow\",\"resources\":[\"*\"]}],\"version\":\"2026-05-10\"}"
      json_sha256 = "deadbeef"
      version     = "2026-05-10"
    }
  }
}

run "creates_with_statements" {
  command = plan
  variables {
    name        = "RegistryAdminCustom"
    description = "Push/Pull on prod-* registries"
    statements = [
      {
        effect    = "Allow"
        actions   = ["registry:Push", "registry:Pull"]
        resources = ["arn:ccp:registry:rnn:tenant-1:registry/prod-*"]
      },
    ]
  }
  assert {
    condition     = ccp_iam_role.this.name == "RegistryAdminCustom"
    error_message = "name not propagated to the resource"
  }
  assert {
    condition     = length(data.ccp_iam_policy_document.this) == 1
    error_message = "policy document data source should be evaluated when statements is set"
  }
}

run "creates_with_raw_json" {
  command = plan
  variables {
    name                 = "FromJson"
    policy_document_json = "{\"version\":\"2026-05-10\",\"statements\":[{\"effect\":\"Allow\",\"actions\":[\"*\"],\"resources\":[\"*\"]}]}"
  }
  assert {
    condition     = ccp_iam_role.this.name == "FromJson"
    error_message = "name not propagated when using raw JSON"
  }
  assert {
    condition     = length(data.ccp_iam_policy_document.this) == 0
    error_message = "policy document data source should NOT be evaluated when raw JSON is used"
  }
}

run "creates_with_conditions_and_multi_stmt" {
  command = plan
  variables {
    name = "BillingViewer"
    statements = [
      {
        sid       = "AllowBillingRead"
        effect    = "Allow"
        actions   = ["billing:Get*", "billing:List*"]
        resources = ["arn:ccp:billing:::tenant-1:*"]
        conditions = [
          {
            test     = "IpAddress"
            variable = "SourceIp"
            values   = ["203.0.113.0/24"]
          },
        ]
      },
      {
        sid       = "DenyDelete"
        effect    = "Deny"
        actions   = ["billing:Delete*"]
        resources = ["*"]
      },
    ]
  }
  assert {
    condition     = ccp_iam_role.this.name == "BillingViewer"
    error_message = "name not propagated"
  }
}

run "rejects_both_inputs" {
  command = plan
  variables {
    name                 = "Both"
    policy_document_json = "{\"version\":\"2026-05-10\",\"statements\":[]}"
    statements = [
      {
        effect    = "Allow"
        actions   = ["registry:*"]
        resources = ["*"]
      },
    ]
  }
  expect_failures = [
    ccp_iam_role.this,
  ]
}

run "rejects_no_input" {
  command = plan
  variables {
    name = "Neither"
  }
  expect_failures = [
    ccp_iam_role.this,
  ]
}

run "rejects_empty_actions" {
  command = plan
  variables {
    name = "EmptyActions"
    statements = [
      {
        effect    = "Allow"
        actions   = []
        resources = ["*"]
      },
    ]
  }
  expect_failures = [
    var.statements,
  ]
}

run "rejects_invalid_effect" {
  command = plan
  variables {
    name = "BadEffect"
    statements = [
      {
        effect    = "Maybe"
        actions   = ["registry:*"]
        resources = ["*"]
      },
    ]
  }
  expect_failures = [
    var.statements,
  ]
}

run "outputs_role_arn_format" {
  command = plan
  variables {
    name = "MyRole"
    statements = [
      {
        effect    = "Allow"
        actions   = ["registry:*"]
        resources = ["*"]
      },
    ]
  }
  assert {
    condition     = output.role_arn == "arn:ccp:iam:::role/MyRole"
    error_message = "role_arn does not follow the expected `arn:ccp:iam:::role/<name>` format"
  }
}
