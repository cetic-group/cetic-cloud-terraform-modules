mock_provider "ccp" {
  mock_resource "ccp_application_gateway" {
    defaults = {
      id                = "00000000-0000-0000-0000-00000000a001"
      status            = "active"
      vip_address       = "10.0.1.10"
      public_ip_address = "203.0.113.10"
    }
  }
}

run "creates_with_minimal" {
  command = plan
  variables {
    name    = "web-appgw"
    region  = "RNN"
    vpc_id  = "00000000-0000-0000-0000-000000000010"
    vnet_id = "00000000-0000-0000-0000-000000000020"
  }
  assert {
    condition     = ccp_application_gateway.this.name == "web-appgw"
    error_message = "name not propagated"
  }
  assert {
    condition     = ccp_application_gateway.this.plan == "small"
    error_message = "default plan should be small"
  }
  assert {
    condition     = ccp_application_gateway.this.force_https == true
    error_message = "force_https default should be true"
  }
}

run "creates_with_full_settings" {
  command = plan
  variables {
    name                      = "prod-appgw"
    region                    = "PAR"
    plan                      = "large"
    vpc_id                    = "00000000-0000-0000-0000-000000000010"
    vnet_id                   = "00000000-0000-0000-0000-000000000020"
    public_ip_id              = "00000000-0000-0000-0000-000000000030"
    hsts_enabled              = true
    hsts_max_age              = 63072000
    global_rate_limit_per_sec = 5000
    global_allow_cidrs        = ["10.0.0.0/8"]
    global_deny_cidrs         = ["192.0.2.0/24"]
    trust_proxy_headers       = true
    tags                      = ["env:prod", "team:platform"]
  }
  assert {
    condition     = ccp_application_gateway.this.plan == "large"
    error_message = "plan should be propagated"
  }
  assert {
    condition     = ccp_application_gateway.this.hsts_enabled == true
    error_message = "hsts_enabled should be propagated"
  }
}

run "rejects_invalid_region" {
  command = plan
  variables {
    name    = "bad"
    region  = "ZZZ"
    vpc_id  = "00000000-0000-0000-0000-000000000010"
    vnet_id = "00000000-0000-0000-0000-000000000020"
  }
  expect_failures = [
    var.region,
  ]
}

run "rejects_invalid_plan" {
  command = plan
  variables {
    name    = "bad-plan"
    region  = "RNN"
    plan    = "xlarge"
    vpc_id  = "00000000-0000-0000-0000-000000000010"
    vnet_id = "00000000-0000-0000-0000-000000000020"
  }
  expect_failures = [
    var.plan,
  ]
}

run "rejects_invalid_cidr" {
  command = plan
  variables {
    name               = "bad-cidr"
    region             = "RNN"
    vpc_id             = "00000000-0000-0000-0000-000000000010"
    vnet_id            = "00000000-0000-0000-0000-000000000020"
    global_allow_cidrs = ["not-a-cidr"]
  }
  expect_failures = [
    var.global_allow_cidrs,
  ]
}
