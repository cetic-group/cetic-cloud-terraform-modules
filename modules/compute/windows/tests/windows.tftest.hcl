# Tests natifs Terraform pour `compute/windows`.
#
# Note : ces tests ne s'exécutent que lorsque le provider `cetic-group/ccp`
# expose la ressource `ccp_windows_instance` (version >= 4.10.0).
# Avant sa release, ces tests resteront en pending (provider schema unknown).

mock_provider "ccp" {
  mock_resource "ccp_windows_instance" {
    defaults = {
      id                = "00000000-0000-0000-0000-0000000000w1"
      status            = "provisioning"
      hostname          = "windows-instance"
      ip_address        = "10.0.0.10"
      public_ip_address = null
      cores             = 3
      memory_mb         = 6144
      disk_gb           = 50
    }
  }
}

run "creates_windows_instance_with_required_variables" {
  command = plan

  variables {
    name                   = "dev-box"
    region                 = "RNN"
    plan                   = "medium"
    template               = "windows-11-pro"
    administrator_password = "SecureP@ss123"
    license_consent        = true
  }

  assert {
    condition     = ccp_windows_instance.this.name == "dev-box"
    error_message = "Le nom doit correspondre à l'input."
  }

  assert {
    condition     = ccp_windows_instance.this.region == "RNN"
    error_message = "La région doit correspondre à l'input."
  }

  assert {
    condition     = ccp_windows_instance.this.plan == "medium"
    error_message = "Le plan doit correspondre à l'input."
  }
}

run "rejects_invalid_region" {
  command = plan

  variables {
    name                   = "test"
    region                 = "LON"
    plan                   = "medium"
    template               = "windows-11-pro"
    administrator_password = "SecureP@ss123"
    license_consent        = true
  }

  expect_failures = [var.region]
}

run "rejects_invalid_plan" {
  command = plan

  variables {
    name                   = "test"
    region                 = "RNN"
    plan                   = "invalid"
    template               = "windows-11-pro"
    administrator_password = "SecureP@ss123"
    license_consent        = true
  }

  expect_failures = [var.plan]
}

run "rejects_short_password" {
  command = plan

  variables {
    name                   = "test"
    region                 = "RNN"
    plan                   = "medium"
    template               = "windows-11-pro"
    administrator_password = "Short1!"
    license_consent        = true
  }

  expect_failures = [var.administrator_password]
}

run "rejects_long_password" {
  command = plan

  variables {
    name                   = "test"
    region                 = "RNN"
    plan                   = "medium"
    template               = "windows-11-pro"
    administrator_password = "This${join("", [for i in range(130) : "X"])}"
    license_consent        = true
  }

  expect_failures = [var.administrator_password]
}

run "rejects_license_not_consented" {
  command = plan

  variables {
    name                   = "test"
    region                 = "RNN"
    plan                   = "medium"
    template               = "windows-11-pro"
    administrator_password = "SecureP@ss123"
    license_consent        = false
  }

  expect_failures = [var.license_consent]
}

run "rejects_too_many_data_volumes" {
  command = plan

  variables {
    name                   = "test"
    region                 = "RNN"
    plan                   = "medium"
    template               = "windows-11-pro"
    administrator_password = "SecureP@ss123"
    license_consent        = true
    data_volume_ids        = ["vol-1", "vol-2", "vol-3", "vol-4", "vol-5", "vol-6"]
  }

  expect_failures = [var.data_volume_ids]
}

run "accepts_five_data_volumes" {
  command = plan

  variables {
    name                   = "test"
    region                 = "RNN"
    plan                   = "medium"
    template               = "windows-11-pro"
    administrator_password = "SecureP@ss123"
    license_consent        = true
    data_volume_ids        = ["vol-1", "vol-2", "vol-3", "vol-4", "vol-5"]
  }

  assert {
    condition     = length(ccp_windows_instance.this.data_volume_ids) == 5
    error_message = "Doit accepter exactement 5 disques de données."
  }
}
