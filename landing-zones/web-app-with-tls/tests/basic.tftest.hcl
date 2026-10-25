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
      id                   = "00000000-0000-0000-0000-00000000f001"
      acme_status          = "pending"
      acme_last_renewal_at = null
      cert_path            = null
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

run "creates_minimal_stack_without_auth" {
  command = plan
  variables {
    org_prefix        = "acme"
    region            = "RNN"
    ssh_public_key    = "ssh-ed25519 AAAA test@example.com"
    hostname          = "app.acme.example.com"
    app_root_password = "test-password-123"
  }
  assert {
    condition     = length(module.appgw.hostnames) == 1
    error_message = "should expose exactly 1 hostname"
  }
  assert {
    condition     = ccp_container_instance.app.region == "RNN"
    error_message = "container should be in RNN region"
  }
}

run "creates_stack_with_basic_auth" {
  command = plan
  variables {
    org_prefix        = "acme"
    region            = "RNN"
    ssh_public_key    = "ssh-ed25519 AAAA test@example.com"
    hostname          = "admin.acme.example.com"
    app_root_password = "test-password-123"
    waf_preset        = "strict"
    basic_auth_users = [
      { user = "alice", password = "alicepw" },
      { user = "bob", password = "bobpw" },
    ]
  }
  assert {
    condition     = module.appgw.hostnames[0] == "admin.acme.example.com"
    error_message = "hostname should be admin.acme.example.com"
  }
}

run "rejects_invalid_hostname" {
  command = plan
  variables {
    org_prefix        = "acme"
    region            = "RNN"
    ssh_public_key    = "ssh-ed25519 AAAA test@example.com"
    hostname          = "UPPER.example.com"
    app_root_password = "test-password-123"
  }
  expect_failures = [
    var.hostname,
  ]
}

run "rejects_invalid_waf_preset" {
  command = plan
  variables {
    org_prefix        = "acme"
    region            = "RNN"
    ssh_public_key    = "ssh-ed25519 AAAA test@example.com"
    hostname          = "app.acme.example.com"
    app_root_password = "test-password-123"
    waf_preset        = "ultra"
  }
  expect_failures = [
    var.waf_preset,
  ]
}

run "rejects_short_root_password" {
  command = plan
  variables {
    org_prefix        = "acme"
    region            = "RNN"
    ssh_public_key    = "ssh-ed25519 AAAA test@example.com"
    hostname          = "app.acme.example.com"
    app_root_password = "short"
  }
  expect_failures = [
    var.app_root_password,
  ]
}

# Toutes les ressources sont simulées par mock_provider.
run "cache_dimensions_follow_provider_profile" {
  command = apply
  variables {
    org_prefix          = "cache"
    region              = "RNN"
    ssh_public_key      = "ssh-ed25519 AAAA test@example.com"
    app_root_password   = "test-password-123"
    appgw_plan          = "medium"
    appgw_cache_enabled = true
    appgw_cache_mode    = "respect"
    hostname            = "cache.example.com"
  }
  override_resource {
    target = module.appgw.module.gateway.ccp_application_gateway.this
    values = {
      cache_size_mb       = 192
      cache_max_object_kb = 384
    }
  }
  assert {
    condition     = module.appgw.cache_enabled && output.appgw_cache_size_mb == 192 && output.appgw_cache_max_object_kb == 384
    error_message = "Gateway activation and server profile must propagate through the landing zone."
  }
}

run "appgw_replica_count_single" {
  command = plan
  variables {
    org_prefix          = "acme"
    region              = "RNN"
    ssh_public_key      = "ssh-ed25519 AAAA test@example.com"
    app_root_password   = "test-password-123"
    hostname            = "app.acme.example.com"
    appgw_replica_count = 1
  }
  assert {
    condition     = output.appgw_replica_count == 1
    error_message = "Le nombre d'instances doit être propagé jusqu'à la ressource et sa sortie."
  }
}

run "appgw_replica_count_default_ha" {
  command = plan
  variables {
    org_prefix        = "acme"
    region            = "RNN"
    ssh_public_key    = "ssh-ed25519 AAAA test@example.com"
    app_root_password = "test-password-123"
    hostname          = "app.acme.example.com"
  }
  assert {
    condition     = output.appgw_replica_count == 2
    error_message = "Le nombre d'instances doit être propagé jusqu'à la ressource et sa sortie."
  }
}

run "appgw_replica_count_rejects_fraction" {
  command = plan
  variables {
    org_prefix          = "acme"
    region              = "RNN"
    ssh_public_key      = "ssh-ed25519 AAAA test@example.com"
    app_root_password   = "test-password-123"
    hostname            = "app.acme.example.com"
    appgw_replica_count = 1.5
  }
  expect_failures = [var.appgw_replica_count]
}
