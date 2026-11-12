mock_provider "ccp" {
  mock_resource "ccp_appgw_target_group" {
    defaults = {
      id            = "00000000-0000-0000-0000-00000000d001"
      kind          = "upstream"
      origin_status = "ok"
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
    appgw_id  = "00000000-0000-0000-0000-00000000a001"
    name      = "api-pool"
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
      vm   = { vm_instance_id = "00000000-0000-0000-0000-00000000c003", port = 80 }
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
    algorithm = "bogus"
  }
  expect_failures = [
    var.algorithm,
  ]
}

run "default_kind_is_upstream" {
  command = plan
  variables {
    appgw_id = "00000000-0000-0000-0000-00000000a001"
    name     = "default-kind"
  }
  assert {
    condition     = ccp_appgw_target_group.this.kind == "upstream"
    error_message = "default kind should be upstream"
  }
}

run "creates_bucket_target_group" {
  command = plan
  variables {
    appgw_id      = "00000000-0000-0000-0000-00000000a001"
    name          = "site"
    kind          = "bucket"
    bucket_id     = "00000000-0000-0000-0000-00000000b001"
    bucket_prefix = "site/images"
  }
  assert {
    condition     = ccp_appgw_target_group.this.kind == "bucket"
    error_message = "kind should be bucket"
  }
  assert {
    condition     = ccp_appgw_target_group.this.bucket_id == "00000000-0000-0000-0000-00000000b001"
    error_message = "bucket_id should be forwarded"
  }
  assert {
    condition     = ccp_appgw_target_group.this.bucket_prefix == "site/images"
    error_message = "bucket_prefix should be forwarded"
  }
  assert {
    condition     = length(ccp_appgw_target_group_member.members) == 0
    error_message = "bucket target group has no members"
  }
}

run "rejects_unknown_kind" {
  command = plan
  variables {
    appgw_id = "00000000-0000-0000-0000-00000000a001"
    name     = "bad-kind"
    kind     = "static"
  }
  expect_failures = [
    var.kind,
  ]
}

run "rejects_bucket_without_bucket_id" {
  command = plan
  variables {
    appgw_id = "00000000-0000-0000-0000-00000000a001"
    name     = "no-bucket"
    kind     = "bucket"
  }
  expect_failures = [
    ccp_appgw_target_group.this,
  ]
}

run "rejects_bucket_id_on_upstream" {
  command = plan
  variables {
    appgw_id  = "00000000-0000-0000-0000-00000000a001"
    name      = "upstream-with-bucket"
    bucket_id = "00000000-0000-0000-0000-00000000b001"
  }
  expect_failures = [
    ccp_appgw_target_group.this,
  ]
}

run "rejects_prefix_on_upstream" {
  command = plan
  variables {
    appgw_id      = "00000000-0000-0000-0000-00000000a001"
    name          = "upstream-with-prefix"
    bucket_prefix = "site"
  }
  expect_failures = [
    ccp_appgw_target_group.this,
  ]
}

run "rejects_bucket_with_members" {
  command = plan
  variables {
    appgw_id  = "00000000-0000-0000-0000-00000000a001"
    name      = "bucket-members"
    kind      = "bucket"
    bucket_id = "00000000-0000-0000-0000-00000000b001"
    members = {
      m1 = { target_ip = "10.0.1.42", port = 80 }
    }
  }
  expect_failures = [
    ccp_appgw_target_group.this,
  ]
}

run "rejects_bucket_with_sticky" {
  command = plan
  variables {
    appgw_id           = "00000000-0000-0000-0000-00000000a001"
    name               = "bucket-sticky"
    kind               = "bucket"
    bucket_id          = "00000000-0000-0000-0000-00000000b001"
    sticky_enabled     = true
    sticky_cookie_name = "SID"
  }
  expect_failures = [
    ccp_appgw_target_group.this,
  ]
}

run "rejects_prefix_with_dotdot" {
  command = plan
  variables {
    appgw_id      = "00000000-0000-0000-0000-00000000a001"
    name          = "bad-prefix"
    kind          = "bucket"
    bucket_id     = "00000000-0000-0000-0000-00000000b001"
    bucket_prefix = "site/../secret"
  }
  expect_failures = [
    var.bucket_prefix,
  ]
}

run "null_kind_falls_back_to_upstream" {
  command = plan
  variables {
    appgw_id = "00000000-0000-0000-0000-00000000a001"
    name     = "null-kind"
    kind     = null
  }
  assert {
    condition     = ccp_appgw_target_group.this.kind == "upstream"
    error_message = "kind = null should fall back to the upstream default"
  }
}

run "rejects_prefix_trailing_slash" {
  command = plan
  variables {
    appgw_id      = "00000000-0000-0000-0000-00000000a001"
    name          = "p1"
    kind          = "bucket"
    bucket_id     = "00000000-0000-0000-0000-00000000b001"
    bucket_prefix = "site/"
  }
  expect_failures = [var.bucket_prefix]
}

run "rejects_prefix_leading_slash" {
  command = plan
  variables {
    appgw_id      = "00000000-0000-0000-0000-00000000a001"
    name          = "p2"
    kind          = "bucket"
    bucket_id     = "00000000-0000-0000-0000-00000000b001"
    bucket_prefix = "/site"
  }
  expect_failures = [var.bucket_prefix]
}

run "rejects_prefix_double_slash" {
  command = plan
  variables {
    appgw_id      = "00000000-0000-0000-0000-00000000a001"
    name          = "p3"
    kind          = "bucket"
    bucket_id     = "00000000-0000-0000-0000-00000000b001"
    bucket_prefix = "a//b"
  }
  expect_failures = [var.bucket_prefix]
}

run "rejects_prefix_single_slash" {
  command = plan
  variables {
    appgw_id      = "00000000-0000-0000-0000-00000000a001"
    name          = "p4"
    kind          = "bucket"
    bucket_id     = "00000000-0000-0000-0000-00000000b001"
    bucket_prefix = "/"
  }
  expect_failures = [var.bucket_prefix]
}

run "accepts_prefix_512_chars" {
  command = plan
  variables {
    appgw_id      = "00000000-0000-0000-0000-00000000a001"
    name          = "p5"
    kind          = "bucket"
    bucket_id     = "00000000-0000-0000-0000-00000000b001"
    bucket_prefix = join("", [for i in range(512) : "a"])
  }
  assert {
    condition     = length(ccp_appgw_target_group.this.bucket_prefix) == 512
    error_message = "a 512 character prefix should be accepted"
  }
}

run "rejects_prefix_513_chars" {
  command = plan
  variables {
    appgw_id      = "00000000-0000-0000-0000-00000000a001"
    name          = "p6"
    kind          = "bucket"
    bucket_id     = "00000000-0000-0000-0000-00000000b001"
    bucket_prefix = join("", [for i in range(513) : "a"])
  }
  expect_failures = [var.bucket_prefix]
}

run "accepts_empty_prefix" {
  command = plan
  variables {
    appgw_id  = "00000000-0000-0000-0000-00000000a001"
    name      = "p7"
    kind      = "bucket"
    bucket_id = "00000000-0000-0000-0000-00000000b001"
  }
  assert {
    condition     = ccp_appgw_target_group.this.bucket_prefix == ""
    error_message = "an empty prefix serves the whole bucket"
  }
}
