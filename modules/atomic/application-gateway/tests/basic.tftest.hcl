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
    condition     = ccp_application_gateway.this.plan == "appgw-small"
    error_message = "default plan should normalize to appgw-small"
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
    condition     = ccp_application_gateway.this.plan == "appgw-large"
    error_message = "short-form plan alias should normalize to appgw-large"
  }
  assert {
    condition     = ccp_application_gateway.this.hsts_enabled == true
    error_message = "hsts_enabled should be propagated"
  }
}

run "accepts_canonical_plan_key" {
  command = plan
  variables {
    name    = "canonical-plan"
    region  = "RNN"
    plan    = "appgw-medium"
    vpc_id  = "00000000-0000-0000-0000-000000000010"
    vnet_id = "00000000-0000-0000-0000-000000000020"
  }
  assert {
    condition     = ccp_application_gateway.this.plan == "appgw-medium"
    error_message = "canonical plan key should be passed through unchanged"
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

run "cache_configuration" {
  command = plan
  variables {
    name          = "cache"
    region        = "RNN"
    vpc_id        = "vpc"
    vnet_id       = "vnet"
    cache_enabled = true
  }
  assert {
    condition     = ccp_application_gateway.this.cache_enabled == true
    error_message = "Cache configuration was not propagated."
  }
}

# Provider intégralement simulé : cet apply de test ne contacte aucune API.
run "cache_profile_is_read_from_provider" {
  command = apply
  variables {
    name          = "profile"
    region        = "RNN"
    vpc_id        = "vpc"
    vnet_id       = "vnet"
    plan          = "appgw-medium"
    cache_enabled = true
  }
  override_resource {
    target = ccp_application_gateway.this
    values = {
      cache_size_mb           = 192
      cache_max_object_kb     = 384
      cache_effective_size_mb = 192
      cache_size_limit_mb     = 192
    }
  }
  assert {
    condition     = output.cache_size_mb == 192 && output.cache_max_object_kb == 384
    error_message = "Cache dimensions must come from the provider, without a module profile table."
  }
  assert {
    condition     = output.cache_enabled && output.cache_effective_size_mb == 192 && output.cache_size_limit_mb == 192
    error_message = "Computed cache profile and activation were not propagated."
  }
}

run "replica_count_single" {
  command = plan
  variables {
    name          = "single-test"
    region        = "RNN"
    vnet_id       = "00000000-0000-0000-0000-000000000020"
    vpc_id        = "00000000-0000-0000-0000-000000000010"
    replica_count = 1
  }
  assert {
    condition     = output.replica_count == 1
    error_message = "Le nombre d'instances doit être propagé jusqu'à la ressource et sa sortie."
  }
}

run "replica_count_default_ha" {
  command = plan
  variables {
    name    = "single-test"
    region  = "RNN"
    vnet_id = "00000000-0000-0000-0000-000000000020"
    vpc_id  = "00000000-0000-0000-0000-000000000010"
  }
  assert {
    condition     = output.replica_count == 2
    error_message = "Le nombre d'instances doit être propagé jusqu'à la ressource et sa sortie."
  }
}

run "replica_count_rejects_fraction" {
  command = plan
  variables {
    name          = "single-test"
    region        = "RNN"
    vnet_id       = "00000000-0000-0000-0000-000000000020"
    vpc_id        = "00000000-0000-0000-0000-000000000010"
    replica_count = 1.5
  }
  expect_failures = [var.replica_count]
}

run "typed_security_policy" {
  command = plan
  variables {
    name      = "policy-test"
    region    = "RNN"
    vpc_id    = "vpc"
    vnet_id   = "vnet"
    l7_policy = { enabled = true, policies = { partners = { required_headers = { id = { name = "X-Partner", op = "in", values = ["a", "b"] } } } } }
  }
  assert {
    condition     = ccp_application_gateway.this.l7_policy.policies.partners.required_headers.id.values == tolist(["a", "b"])
    error_message = "Typed mandatory header policy must reach the provider unchanged."
  }
}
run "explicit_security_reset" {
  command = plan
  variables {
    name      = "policy-test"
    region    = "RNN"
    vpc_id    = "vpc"
    vnet_id   = "vnet"
    l7_policy = {}
  }
  assert {
    condition     = ccp_application_gateway.this.l7_policy != null && ccp_application_gateway.this.l7_policy.enabled == null && ccp_application_gateway.this.l7_policy.policies == null
    error_message = "Explicit empty object must be distinct from an omitted policy."
  }
}
