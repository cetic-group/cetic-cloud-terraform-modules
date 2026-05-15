mock_provider "ccp" {
  mock_resource "ccp_appgw_route" {
    defaults = {
      id = "00000000-0000-0000-0000-00000000b001"
    }
  }
}

run "creates_default_route" {
  command = plan
  variables {
    appgw_id        = "00000000-0000-0000-0000-00000000a001"
    listener_id     = "00000000-0000-0000-0000-00000000c001"
    target_group_id = "00000000-0000-0000-0000-00000000d001"
  }
  assert {
    condition     = ccp_appgw_route.this.priority == 100
    error_message = "default priority should be 100"
  }
  assert {
    condition     = ccp_appgw_route.this.path_match_type == "prefix"
    error_message = "default path_match_type should be prefix"
  }
  assert {
    condition     = ccp_appgw_route.this.waf_preset == "off"
    error_message = "default waf_preset should be off"
  }
}

run "creates_full_policies_route" {
  command = plan
  variables {
    appgw_id        = "00000000-0000-0000-0000-00000000a001"
    listener_id     = "00000000-0000-0000-0000-00000000c001"
    target_group_id = "00000000-0000-0000-0000-00000000d001"
    priority        = 10
    path_match      = "/api/v1/"
    path_match_type = "prefix"
    method_match    = ["GET", "POST"]
    header_matches = [
      { name = "X-API-Version", value = "v1", op = "eq" },
    ]
    rate_limit_per_sec = 200
    allow_cidrs        = ["10.0.0.0/8"]
    cors_enabled       = true
    cors_origins       = ["https://app.example.com"]
    cors_credentials   = true
    waf_preset         = "strict"
  }
  assert {
    condition     = ccp_appgw_route.this.priority == 10
    error_message = "priority should be propagated"
  }
  assert {
    condition     = ccp_appgw_route.this.waf_preset == "strict"
    error_message = "waf_preset should be strict"
  }
}

run "rejects_invalid_path_match_type" {
  command = plan
  variables {
    appgw_id        = "00000000-0000-0000-0000-00000000a001"
    listener_id     = "00000000-0000-0000-0000-00000000c001"
    target_group_id = "00000000-0000-0000-0000-00000000d001"
    path_match_type = "glob"
  }
  expect_failures = [
    var.path_match_type,
  ]
}

run "rejects_invalid_waf_preset" {
  command = plan
  variables {
    appgw_id        = "00000000-0000-0000-0000-00000000a001"
    listener_id     = "00000000-0000-0000-0000-00000000c001"
    target_group_id = "00000000-0000-0000-0000-00000000d001"
    waf_preset      = "paranoid"
  }
  expect_failures = [
    var.waf_preset,
  ]
}

run "rejects_credentials_with_wildcard_origin" {
  command = plan
  variables {
    appgw_id         = "00000000-0000-0000-0000-00000000a001"
    listener_id      = "00000000-0000-0000-0000-00000000c001"
    target_group_id  = "00000000-0000-0000-0000-00000000d001"
    cors_enabled     = true
    cors_origins     = ["*"]
    cors_credentials = true
  }
  expect_failures = [
    ccp_appgw_route.this,
  ]
}

run "rejects_invalid_cidr" {
  command = plan
  variables {
    appgw_id        = "00000000-0000-0000-0000-00000000a001"
    listener_id     = "00000000-0000-0000-0000-00000000c001"
    target_group_id = "00000000-0000-0000-0000-00000000d001"
    allow_cidrs     = ["bad"]
  }
  expect_failures = [
    var.allow_cidrs,
  ]
}
