mock_provider "ccp" {
  mock_resource "ccp_vpc" {
    defaults = {
      id     = "00000000-0000-0000-0000-000000000001"
      status = "active"
    }
  }
  mock_resource "ccp_vnet" {
    defaults = {
      id              = "00000000-0000-0000-0000-000000000002"
      vnet_address    = "10.0.1.1"
      isolation_state = "open"
    }
  }
  mock_resource "ccp_vnet_firewall_rule" {
    defaults = {
      id = "00000000-0000-0000-0000-000000000003"
    }
  }
  mock_resource "ccp_vnet_ip_reservation" {
    defaults = {
      id = "00000000-0000-0000-0000-000000000004"
    }
  }
  mock_resource "ccp_ssh_key" {
    defaults = {
      id          = "00000000-0000-0000-0000-000000000005"
      fingerprint = "SHA256:abcd"
    }
  }
  mock_resource "ccp_container_instance" {
    defaults = {
      id                = "00000000-0000-0000-0000-000000000006"
      status            = "running"
      ip_address        = "10.0.1.20"
      public_ip_address = null
      cores             = 1
      memory_mb         = 1024
      disk_gb           = 10
    }
  }
  mock_resource "ccp_public_ip" {
    defaults = {
      id         = "00000000-0000-0000-0000-000000000007"
      ip_address = "203.0.113.10"
    }
  }
  mock_resource "ccp_load_balancer" {
    defaults = {
      id                = "00000000-0000-0000-0000-000000000008"
      vip_address       = "10.0.1.10"
      public_ip_address = "203.0.113.10"
      status            = "active"
    }
  }
  mock_resource "ccp_db_pg_instance" {
    defaults = {
      id               = "00000000-0000-0000-0000-000000000009"
      endpoint_vnet_ip = "10.0.2.20"
      endpoint_port    = 5432
      admin_username   = "ccpadmin"
      admin_database   = "appdb"
      tier             = "dev"
    }
  }
  mock_resource "ccp_application_gateway" {
    defaults = {
      id                = "00000000-0000-0000-0000-00000000a001"
      status            = "active"
      vip_address       = "10.0.1.11"
      public_ip_address = "203.0.113.10"
    }
  }
  mock_resource "ccp_appgw_listener" {
    defaults = {
      id          = "00000000-0000-0000-0000-00000000f001"
      acme_status = "issued"
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
      id = "00000000-0000-0000-0000-00000000b001"
    }
  }
}

run "default_lb_mode_still_works" {
  command = plan
  variables {
    org_prefix        = "acme"
    region            = "RNN"
    ssh_public_key    = "ssh-ed25519 AAAA test@example.com"
    app_root_password = "test-password-123"
    enable_database   = false
  }
  assert {
    condition     = length(ccp_load_balancer.this) == 1
    error_message = "default exposure_type=lb should create a load balancer"
  }
  assert {
    condition     = length(module.appgw) == 0
    error_message = "default mode should NOT create an appgw"
  }
}

run "appgw_mode_creates_gateway" {
  command = plan
  variables {
    org_prefix        = "acme"
    region            = "RNN"
    ssh_public_key    = "ssh-ed25519 AAAA test@example.com"
    app_root_password = "test-password-123"
    enable_database   = false

    exposure_type        = "appgw"
    appgw_plan           = "medium"
    appgw_hostname       = "app.example.com"
    appgw_custom_domain  = true
    appgw_hsts_enabled   = true
    appgw_rate_limit_per_sec = 500
  }
  assert {
    condition     = length(ccp_load_balancer.this) == 0
    error_message = "exposure_type=appgw should NOT create a load balancer"
  }
  assert {
    condition     = length(module.appgw) == 1
    error_message = "exposure_type=appgw should create exactly 1 appgw module"
  }
}

run "appgw_mode_with_auto_hostname" {
  command = plan
  variables {
    org_prefix        = "acme"
    region            = "RNN"
    ssh_public_key    = "ssh-ed25519 AAAA test@example.com"
    app_root_password = "test-password-123"
    enable_database   = false

    exposure_type = "appgw"
    # appgw_hostname unset → auto-derived
  }
  assert {
    condition     = length(module.appgw) == 1
    error_message = "appgw should still provision with auto hostname"
  }
}

run "rejects_invalid_exposure_type" {
  command = plan
  variables {
    org_prefix        = "acme"
    region            = "RNN"
    ssh_public_key    = "ssh-ed25519 AAAA test@example.com"
    app_root_password = "test-password-123"
    enable_database   = false

    exposure_type = "ingress-controller"
  }
  expect_failures = [
    var.exposure_type,
  ]
}

run "rejects_invalid_appgw_plan" {
  command = plan
  variables {
    org_prefix        = "acme"
    region            = "RNN"
    ssh_public_key    = "ssh-ed25519 AAAA test@example.com"
    app_root_password = "test-password-123"
    enable_database   = false

    exposure_type = "appgw"
    appgw_plan    = "xxl"
  }
  expect_failures = [
    var.appgw_plan,
  ]
}
