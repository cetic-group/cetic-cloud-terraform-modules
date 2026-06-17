# Tests natifs Terraform pour `compute/vm-scale-set`.

mock_provider "ccp" {
  mock_resource "ccp_vm_scale_set" {
    defaults = {
      id        = "00000000-0000-0000-0000-000000000002"
      status    = "provisioning"
      os_family = "linux"
    }
  }
}

run "linux_vmss_defaults" {
  command = plan

  variables {
    name              = "test-linux-pool"
    region            = "RNN"
    vnet_id           = "00000000-0000-0000-0000-0000000000bb"
    desired_instances = 2
    min_instances     = 1
    max_instances     = 4
    root_password     = "changeme123"
  }

  assert {
    condition     = ccp_vm_scale_set.this.windows_license_consent == false
    error_message = "windows_license_consent doit défaut à false."
  }
}

run "windows_vmss_license_consent_passthrough" {
  command = plan

  variables {
    name                    = "test-win-pool"
    region                  = "RNN"
    plan                    = "medium"
    template                = "win-2022"
    vnet_id                 = "00000000-0000-0000-0000-0000000000bb"
    desired_instances       = 2
    min_instances           = 1
    max_instances           = 4
    root_password           = "Str0ng-P@ssw0rd!"
    windows_license_consent = true
  }

  assert {
    condition     = ccp_vm_scale_set.this.windows_license_consent == true
    error_message = "windows_license_consent doit être propagé à la ressource."
  }
}
