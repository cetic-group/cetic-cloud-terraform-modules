# Tests natifs Terraform pour `compute/vm`.

mock_provider "ccp" {
  mock_resource "ccp_vm_instance" {
    defaults = {
      id                = "00000000-0000-0000-0000-000000000001"
      status            = "provisioning"
      os_family         = "linux"
      ip_address        = "10.10.0.10"
      public_ip_address = null
      cores             = 4
      memory_mb         = 8192
      disk_gb           = 80
    }
  }
}

run "linux_vm_defaults" {
  command = plan

  variables {
    name          = "test-linux"
    region        = "RNN"
    vnet_id       = "00000000-0000-0000-0000-0000000000bb"
    root_password = "changeme123"
  }

  assert {
    condition     = ccp_vm_instance.this.windows_license_consent == false
    error_message = "windows_license_consent doit défaut à false."
  }
}

run "windows_vm_license_consent_passthrough" {
  command = plan

  variables {
    name                    = "test-win"
    region                  = "RNN"
    plan                    = "medium"
    template                = "win-2022"
    vnet_id                 = "00000000-0000-0000-0000-0000000000bb"
    root_password           = "Str0ng-P@ssw0rd!"
    windows_license_consent = true
  }

  assert {
    condition     = ccp_vm_instance.this.windows_license_consent == true
    error_message = "windows_license_consent doit être propagé à la ressource."
  }

  assert {
    condition     = ccp_vm_instance.this.template == "win-2022"
    error_message = "Le template Windows doit être propagé."
  }
}

run "disk_gb_passthrough" {
  command = plan

  variables {
    name          = "test-disk"
    region        = "RNN"
    plan          = "medium"
    vnet_id       = "00000000-0000-0000-0000-0000000000bb"
    root_password = "changeme123"
    disk_gb       = 150
  }

  assert {
    condition     = ccp_vm_instance.this.disk_gb == 150
    error_message = "disk_gb doit être propagé à la ressource."
  }
}
