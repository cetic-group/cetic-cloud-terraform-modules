mock_provider "ccp" {
  mock_resource "ccp_registry" {
    defaults = {
      id              = "00000000-0000-0000-0000-000000000001"
      slug            = "test"
      url             = "https://test-aabbccdd.registry-rnn.cloud.cetic-group.com"
      status          = "active"
      admin_username  = "admin"
      admin_password  = "secret"
      gc_schedule_cron = "0 3 * * 0"
    }
  }
}

run "creates_with_private_only" {
  command = plan
  variables {
    name           = "test"
    region         = "RNN"
    expose_public  = false
    expose_private = true
  }
  assert {
    condition     = ccp_registry.this.name == "test"
    error_message = "name not propagated"
  }
  assert {
    condition     = ccp_registry.this.expose_private == true
    error_message = "expose_private should be true"
  }
}

run "creates_with_both_exposures" {
  command = plan
  variables {
    name           = "prod"
    region         = "RNN"
    expose_public  = true
    expose_private = true
  }
  assert {
    condition     = ccp_registry.this.expose_public == true
    error_message = "expose_public should be true"
  }
}

run "rejects_no_exposure" {
  command = plan
  variables {
    name           = "bad"
    region         = "RNN"
    expose_public  = false
    expose_private = false
  }
  expect_failures = [
    ccp_registry.this,
  ]
}

run "rejects_invalid_region" {
  command = plan
  variables {
    name           = "test"
    region         = "ZZZ"
    expose_public  = true
    expose_private = false
  }
  expect_failures = [
    var.region,
  ]
}
