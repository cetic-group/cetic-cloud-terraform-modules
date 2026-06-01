# Tests natifs Terraform pour `storage/block-volume`.
#
# Régression v0.17.1 : le provider attend `attached_to_type = "vm"` depuis
# v0.24+ (TypeName aligné). Le module acceptait/transmettait l'alias legacy
# `vm_instance` tel quel → le provider rejetait. Le module mappe désormais
# `vm_instance` → `vm` (alias déprécié) et accepte aussi `vm` directement.

mock_provider "ccp" {
  mock_resource "ccp_block_volume" {
    defaults = {
      id     = "00000000-0000-0000-0000-0000000000c1"
      status = "available"
    }
  }
}

run "maps_vm_instance_alias_to_vm" {
  command = plan

  variables {
    name    = "vol-test"
    region  = "RNN"
    size_gb = 10
    attach_to = {
      id   = "00000000-0000-0000-0000-0000000000d1"
      type = "vm_instance"
    }
  }

  assert {
    condition     = ccp_block_volume.this.attached_to_type == "vm"
    error_message = "L'alias legacy `vm_instance` doit être mappé sur `vm` (attendu par le provider v0.24+)."
  }
}

run "passes_vm_through" {
  command = plan

  variables {
    name    = "vol-test-vm"
    region  = "RNN"
    size_gb = 10
    attach_to = {
      id   = "00000000-0000-0000-0000-0000000000d2"
      type = "vm"
    }
  }

  assert {
    condition     = ccp_block_volume.this.attached_to_type == "vm"
    error_message = "`vm` doit être transmis tel quel."
  }
}

run "passes_container_through" {
  command = plan

  variables {
    name    = "vol-test-ct"
    region  = "RNN"
    size_gb = 10
    attach_to = {
      id   = "00000000-0000-0000-0000-0000000000d3"
      type = "container"
    }
  }

  assert {
    condition     = ccp_block_volume.this.attached_to_type == "container"
    error_message = "`container` doit être transmis tel quel."
  }
}

run "rejects_invalid_type" {
  command = plan

  variables {
    name    = "vol-test-bad"
    region  = "RNN"
    size_gb = 10
    attach_to = {
      id   = "00000000-0000-0000-0000-0000000000d4"
      type = "droplet"
    }
  }

  expect_failures = [var.attach_to]
}
