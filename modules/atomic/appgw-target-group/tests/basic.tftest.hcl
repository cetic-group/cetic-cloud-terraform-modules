mock_provider "ccp" {
  mock_resource "ccp_appgw_target_group" {
    defaults = {
      id = "00000000-0000-0000-0000-00000000d001"
    }
  }
  mock_resource "ccp_appgw_target_group_member" {
    defaults = {
      id = "00000000-0000-0000-0000-00000000e001"
    }
  }
}

run "creates_with_defaults" {
  command = plan
  variables {
    appgw_id = "00000000-0000-0000-0000-00000000a001"
    name     = "default-pool"
  }
  assert {
    condition     = ccp_appgw_target_group.this.algorithm == "roundrobin"
    error_message = "default algorithm should be roundrobin"
  }
  assert {
    condition     = ccp_appgw_target_group.this.hc_protocol == "http"
    error_message = "default hc protocol should be http"
  }
  assert {
    condition     = ccp_appgw_target_group.this.hc_path == "/"
    error_message = "default hc path should be /"
  }
}

run "creates_with_container_members" {
  command = plan
  variables {
    appgw_id = "00000000-0000-0000-0000-00000000a001"
    name     = "api-pool"
    algorithm = "leastconn"
    health_check = {
      protocol      = "http"
      path          = "/healthz"
      expect_status = 200
    }
    members = {
      api_01 = { container_id = "00000000-0000-0000-0000-00000000c001", port = 8080 }
      api_02 = { container_id = "00000000-0000-0000-0000-00000000c002", port = 8080, weight = 50 }
    }
  }
  assert {
    condition     = length(ccp_appgw_target_group_member.members) == 2
    error_message = "should create 2 members"
  }
  assert {
    condition     = ccp_appgw_target_group.this.algorithm == "leastconn"
    error_message = "algorithm should be leastconn"
  }
}

run "creates_with_mixed_members" {
  command = plan
  variables {
    appgw_id = "00000000-0000-0000-0000-00000000a001"
    name     = "mixed-pool"
    members = {
      vm  = { vm_instance_id = "00000000-0000-0000-0000-00000000c003", port = 80 }
      bare = { target_ip = "10.0.1.42", port = 80 }
    }
  }
  assert {
    condition     = length(ccp_appgw_target_group_member.members) == 2
    error_message = "should create 2 mixed members"
  }
}

run "creates_with_sticky_session" {
  command = plan
  variables {
    appgw_id           = "00000000-0000-0000-0000-00000000a001"
    name               = "sticky-pool"
    sticky_enabled     = true
    sticky_cookie_name = "JSESSIONID"
    members = {
      m1 = { container_id = "00000000-0000-0000-0000-00000000c001", port = 8080 }
    }
  }
  assert {
    condition     = ccp_appgw_target_group.this.sticky_enabled == true
    error_message = "sticky_enabled should be true"
  }
}

run "rejects_sticky_without_cookie" {
  command = plan
  variables {
    appgw_id       = "00000000-0000-0000-0000-00000000a001"
    name           = "sticky-bad"
    sticky_enabled = true
    members = {
      m1 = { container_id = "00000000-0000-0000-0000-00000000c001", port = 8080 }
    }
  }
  expect_failures = [
    ccp_appgw_target_group.this,
  ]
}

run "rejects_member_with_multiple_targets" {
  command = plan
  variables {
    appgw_id = "00000000-0000-0000-0000-00000000a001"
    name     = "bad-member"
    members = {
      bad = {
        container_id   = "00000000-0000-0000-0000-00000000c001"
        vm_instance_id = "00000000-0000-0000-0000-00000000c002"
        port           = 8080
      }
    }
  }
  expect_failures = [
    var.members,
  ]
}

run "rejects_member_without_target" {
  command = plan
  variables {
    appgw_id = "00000000-0000-0000-0000-00000000a001"
    name     = "bad-no-target"
    members = {
      orphan = { port = 8080 }
    }
  }
  expect_failures = [
    var.members,
  ]
}

run "rejects_invalid_algorithm" {
  command = plan
  variables {
    appgw_id  = "00000000-0000-0000-0000-00000000a001"
    name      = "bad-algo"
    algorithm = "random"
  }
  expect_failures = [
    var.algorithm,
  ]
}
