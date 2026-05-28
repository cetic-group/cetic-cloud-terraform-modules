# Tests natifs Terraform pour `exposure/load-balancer`.

mock_provider "cetic-cloud-platform" {
  mock_resource "ccp_load_balancer" {
    defaults = {
      id                = "00000000-0000-0000-0000-0000000000a1"
      vip_address       = "10.0.1.10"
      public_ip_address = null
      status            = "active"
    }
  }
}

run "creates_lb_with_default_plan" {
  command = plan

  variables {
    name    = "test-lb"
    region  = "RNN"
    vnet_id = "00000000-0000-0000-0000-0000000000b1"
  }

  assert {
    condition     = ccp_load_balancer.this.plan == "small"
    error_message = "Le plan par défaut doit être `small`."
  }

  assert {
    condition     = ccp_load_balancer.this.name == "test-lb"
    error_message = "Le nom doit refléter l'input."
  }
}

run "creates_lb_with_medium_plan" {
  command = plan

  variables {
    name    = "test-lb-medium"
    region  = "RNN"
    vnet_id = "00000000-0000-0000-0000-0000000000b1"
    plan    = "medium"
  }

  assert {
    condition     = ccp_load_balancer.this.plan == "medium"
    error_message = "Le plan doit être propagé jusqu'à la resource."
  }
}

run "creates_lb_with_large_plan" {
  command = plan

  variables {
    name    = "test-lb-large"
    region  = "RNN"
    vnet_id = "00000000-0000-0000-0000-0000000000b1"
    plan    = "large"
  }

  assert {
    condition     = ccp_load_balancer.this.plan == "large"
    error_message = "Le plan `large` doit être propagé."
  }
}

run "rejects_invalid_plan" {
  command = plan

  variables {
    name    = "bad-plan-lb"
    region  = "RNN"
    vnet_id = "00000000-0000-0000-0000-0000000000b1"
    plan    = "xlarge"
  }

  expect_failures = [
    var.plan,
  ]
}

run "rejects_invalid_region" {
  command = plan

  variables {
    name    = "bad-region-lb"
    region  = "XXX"
    vnet_id = "00000000-0000-0000-0000-0000000000b1"
  }

  expect_failures = [
    var.region,
  ]
}
