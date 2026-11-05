mock_provider "ccp" {
  mock_resource "ccp_application_gateway" {
    defaults = {
      id                = "00000000-0000-0000-0000-00000000a001"
      status            = "active"
      vip_address       = "10.0.1.10"
      public_ip_address = "203.0.113.10"
    }
  }
  mock_resource "ccp_appgw_listener" {
    defaults = {
      id                   = "00000000-0000-0000-0000-00000000f001"
      acme_status          = "issued"
      acme_last_renewal_at = "2026-05-16T08:00:00Z"
      cert_path            = "/var/lib/ccp-appgw/certs/x.pem"
      created_at           = "2026-05-16T07:00:00Z"
    }
  }
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
  mock_resource "ccp_appgw_route" {
    defaults = {
      id                    = "00000000-0000-0000-0000-00000000b001"
      basic_auth_secret_ref = null
    }
  }
}

run "creates_single_host_single_route" {
  command = plan
  variables {
    name    = "minimal"
    region  = "RNN"
    vpc_id  = "00000000-0000-0000-0000-000000000010"
    vnet_id = "00000000-0000-0000-0000-000000000020"

    hostnames = ["app.example.com"]

    target_groups = {
      default = {
        members = {
          m1 = { container_id = "00000000-0000-0000-0000-00000000c001", port = 8080 }
        }
      }
    }

    routes = [
      {
        listener_index   = 0
        target_group_key = "default"
      },
    ]
  }
  assert {
    condition     = length(module.listeners) == 1
    error_message = "should create 1 listener"
  }
  assert {
    condition     = length(module.routes) == 1
    error_message = "should create 1 route"
  }
}

run "creates_two_hosts_two_target_groups_with_basic_auth" {
  command = plan
  variables {
    name    = "api-admin"
    region  = "RNN"
    plan    = "medium"
    vpc_id  = "00000000-0000-0000-0000-000000000010"
    vnet_id = "00000000-0000-0000-0000-000000000020"

    hostnames = ["api.example.com", "admin.example.com"]

    target_groups = {
      api = {
        algorithm = "leastconn"
        members = {
          api_01 = { container_id = "00000000-0000-0000-0000-00000000c001", port = 8080 }
          api_02 = { container_id = "00000000-0000-0000-0000-00000000c002", port = 8080 }
        }
      }
      admin = {
        members = {
          admin_01 = { container_id = "00000000-0000-0000-0000-00000000c003", port = 4000 }
        }
      }
    }

    routes = [
      {
        listener_index   = 0
        target_group_key = "api"
        priority         = 10
        policies = {
          rate_limit_per_sec = 500
          waf_preset         = "strict"
        }
      },
      {
        listener_index   = 1
        target_group_key = "admin"
        priority         = 10
        policies = {
          allow_cidrs = ["203.0.113.0/24"]
          basic_auth_users = [
            { user = "alice", password = "s3cret!" },
          ]
          waf_preset = "strict"
        }
      },
    ]
  }
  assert {
    condition     = length(module.listeners) == 2
    error_message = "should create 2 listeners"
  }
  assert {
    condition     = length(module.target_groups) == 2
    error_message = "should create 2 target groups"
  }
  assert {
    condition     = length(module.routes) == 2
    error_message = "should create 2 routes"
  }
}

run "rejects_empty_hostnames" {
  command = plan
  variables {
    name    = "empty"
    region  = "RNN"
    vpc_id  = "00000000-0000-0000-0000-000000000010"
    vnet_id = "00000000-0000-0000-0000-000000000020"

    hostnames = []
    target_groups = {
      default = {
        members = { m1 = { container_id = "00000000-0000-0000-0000-00000000c001", port = 8080 } }
      }
    }
    routes = [{ listener_index = 0, target_group_key = "default" }]
  }
  expect_failures = [
    var.hostnames,
  ]
}

run "rejects_invalid_hostname" {
  command = plan
  variables {
    name    = "bad"
    region  = "RNN"
    vpc_id  = "00000000-0000-0000-0000-000000000010"
    vnet_id = "00000000-0000-0000-0000-000000000020"

    hostnames = ["UPPER.example.com"]
    target_groups = {
      default = {
        members = { m1 = { container_id = "00000000-0000-0000-0000-00000000c001", port = 8080 } }
      }
    }
    routes = [{ listener_index = 0, target_group_key = "default" }]
  }
  expect_failures = [
    var.hostnames,
  ]
}

run "replica_count_single" {
  command = plan
  variables {
    name          = "single-test"
    region        = "RNN"
    vnet_id       = "00000000-0000-0000-0000-000000000020"
    vpc_id        = "00000000-0000-0000-0000-000000000010"
    target_groups = { default = { members = { m1 = { container_id = "00000000-0000-0000-0000-00000000c001", port = 8080 } } } }
    routes        = [{ listener_index = 0, target_group_key = "default" }]
    hostnames     = ["app.example.com"]
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
    name          = "single-test"
    region        = "RNN"
    vnet_id       = "00000000-0000-0000-0000-000000000020"
    vpc_id        = "00000000-0000-0000-0000-000000000010"
    target_groups = { default = { members = { m1 = { container_id = "00000000-0000-0000-0000-00000000c001", port = 8080 } } } }
    routes        = [{ listener_index = 0, target_group_key = "default" }]
    hostnames     = ["app.example.com"]
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
    target_groups = { default = { members = { m1 = { container_id = "00000000-0000-0000-0000-00000000c001", port = 8080 } } } }
    routes        = [{ listener_index = 0, target_group_key = "default" }]
    hostnames     = ["app.example.com"]
    replica_count = 1.5
  }
  expect_failures = [var.replica_count]
}

run "policies_on_all_scopes" {
  command = plan
  variables {
    name                 = "policy-test"
    region               = "RNN"
    vpc_id               = "vpc"
    vnet_id              = "vnet"
    hostnames            = ["app.example.com"]
    target_groups        = { default = { members = { app = { target_ip = "10.0.0.2", port = 8080 } } } }
    routes               = [{ listener_index = 0, target_group_key = "default", l7_policy = { enabled = true, policies = { partners = { required_headers = { id = { name = "X-Partner", op = "in", values = ["a", "b"] } } } } } }]
    l7_policy            = { enabled = true, policies = { partners = { required_headers = { id = { name = "X-Partner", op = "in", values = ["a", "b"] } } } } }
    listener_l7_policies = { "app.example.com" = { enabled = true, policies = { partners = { required_headers = { id = { name = "X-Partner", op = "in", values = ["a", "b"] } } } } } }
  }
  assert {
    condition     = module.gateway.l7_policy.enabled && module.listeners["0"].l7_policy.enabled && module.routes[0].l7_policy.enabled
    error_message = "Gateway, listener and route policies must all propagate."
  }
}
run "reject_unmapped_listener_policy" {
  command = plan
  variables {
    name                 = "policy-test"
    region               = "RNN"
    vpc_id               = "vpc"
    vnet_id              = "vnet"
    hostnames            = ["app.example.com"]
    target_groups        = { default = { members = { app = { target_ip = "10.0.0.2", port = 8080 } } } }
    routes               = [{ listener_index = 0, target_group_key = "default", l7_policy = { enabled = true, policies = { partners = { required_headers = { id = { name = "X-Partner", op = "in", values = ["a", "b"] } } } } } }]
    l7_policy            = { enabled = true, policies = { partners = { required_headers = { id = { name = "X-Partner", op = "in", values = ["a", "b"] } } } } }
    listener_l7_policies = { "typo.example.com" = { enabled = true, policies = { partners = { required_headers = { id = { name = "X-Partner", op = "in", values = ["a", "b"] } } } } } }
  }
  expect_failures = [var.listener_l7_policies]
}
