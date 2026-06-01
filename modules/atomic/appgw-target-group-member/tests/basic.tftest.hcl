mock_provider "ccp" {
  mock_resource "ccp_appgw_target_group_member" {
    defaults = {
      id      = "00000000-0000-0000-0000-00000000e001"
      enabled = true
    }
  }
}

run "creates_with_container_id" {
  command = plan
  variables {
    appgw_id        = "00000000-0000-0000-0000-00000000a001"
    target_group_id = "00000000-0000-0000-0000-00000000d001"
    container_id    = "00000000-0000-0000-0000-00000000c001"
    port            = 8080
  }
  assert {
    condition     = ccp_appgw_target_group_member.this.port == 8080
    error_message = "port not propagated"
  }
  assert {
    condition     = ccp_appgw_target_group_member.this.weight == 100
    error_message = "default weight should be 100"
  }
  assert {
    condition     = ccp_appgw_target_group_member.this.enabled == true
    error_message = "default enabled should be true"
  }
}

run "creates_with_target_ip_disabled" {
  command = plan
  variables {
    appgw_id        = "00000000-0000-0000-0000-00000000a001"
    target_group_id = "00000000-0000-0000-0000-00000000d001"
    target_ip       = "10.0.1.42"
    port            = 8080
    weight          = 0
    enabled         = false
  }
  assert {
    condition     = ccp_appgw_target_group_member.this.enabled == false
    error_message = "enabled should be false for drain"
  }
  assert {
    condition     = ccp_appgw_target_group_member.this.weight == 0
    error_message = "weight should be 0 for drain"
  }
}

run "rejects_no_target" {
  command = plan
  variables {
    appgw_id        = "00000000-0000-0000-0000-00000000a001"
    target_group_id = "00000000-0000-0000-0000-00000000d001"
    port            = 8080
  }
  expect_failures = [
    ccp_appgw_target_group_member.this,
  ]
}

run "rejects_multiple_targets" {
  command = plan
  variables {
    appgw_id        = "00000000-0000-0000-0000-00000000a001"
    target_group_id = "00000000-0000-0000-0000-00000000d001"
    container_id    = "00000000-0000-0000-0000-00000000c001"
    vm_instance_id  = "00000000-0000-0000-0000-00000000c002"
    port            = 8080
  }
  expect_failures = [
    ccp_appgw_target_group_member.this,
  ]
}

run "rejects_invalid_port" {
  command = plan
  variables {
    appgw_id        = "00000000-0000-0000-0000-00000000a001"
    target_group_id = "00000000-0000-0000-0000-00000000d001"
    container_id    = "00000000-0000-0000-0000-00000000c001"
    port            = 70000
  }
  expect_failures = [
    var.port,
  ]
}

run "rejects_invalid_weight" {
  command = plan
  variables {
    appgw_id        = "00000000-0000-0000-0000-00000000a001"
    target_group_id = "00000000-0000-0000-0000-00000000d001"
    container_id    = "00000000-0000-0000-0000-00000000c001"
    port            = 8080
    weight          = 5000
  }
  expect_failures = [
    var.weight,
  ]
}
