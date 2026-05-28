# Tests natifs Terraform pour `atomic/ssh-key`.

mock_provider "cetic-cloud-platform" {
  mock_resource "ccp_ssh_key" {
    defaults = {
      id          = "00000000-0000-0000-0000-000000000099"
      fingerprint = "SHA256:mockfingerprint=="
    }
  }
}

run "creates_ssh_key" {
  command = plan

  variables {
    name       = "test-ed25519"
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBQqn0OHfSEwi1FfbxLFz9e3M+B4N/kd0aeGFRfxKlXa user@host"
  }

  assert {
    condition     = ccp_ssh_key.this.name == "test-ed25519"
    error_message = "Le nom doit refléter l'input."
  }

  assert {
    condition     = startswith(ccp_ssh_key.this.public_key, "ssh-ed25519 ")
    error_message = "La clé publique doit commencer par ssh-ed25519."
  }
}

run "rejects_invalid_public_key_format" {
  command = plan

  variables {
    name       = "bad"
    public_key = "this-is-not-a-valid-openssh-key"
  }

  expect_failures = [
    var.public_key,
  ]
}

run "rejects_empty_name" {
  command = plan

  variables {
    name       = ""
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ user@host"
  }

  expect_failures = [
    var.name,
  ]
}

run "accepts_rsa_key" {
  command = plan

  variables {
    name       = "test-rsa"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDxxxxxxxxxxxxxxxxxxxxxxxxx user@host"
  }

  assert {
    condition     = ccp_ssh_key.this.name == "test-rsa"
    error_message = "Le module doit accepter une clé RSA."
  }
}

run "default_scope_is_user" {
  command = plan

  variables {
    name       = "test-default-scope"
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBQqn0OHfSEwi1FfbxLFz9e3M+B4N/kd0aeGFRfxKlXa user@host"
  }

  assert {
    condition     = ccp_ssh_key.this.scope == "user"
    error_message = "Le scope par défaut doit être `user` (principe du moindre privilège)."
  }
}

run "accepts_scope_org" {
  command = plan

  variables {
    name       = "test-org-scope"
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBQqn0OHfSEwi1FfbxLFz9e3M+B4N/kd0aeGFRfxKlXa user@host"
    scope      = "org"
  }

  assert {
    condition     = ccp_ssh_key.this.scope == "org"
    error_message = "Le scope `org` doit être propagé à la resource provider."
  }
}

run "accepts_scope_tenant" {
  command = plan

  variables {
    name       = "test-tenant-scope"
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBQqn0OHfSEwi1FfbxLFz9e3M+B4N/kd0aeGFRfxKlXa user@host"
    scope      = "tenant"
  }

  assert {
    condition     = ccp_ssh_key.this.scope == "tenant"
    error_message = "Le scope `tenant` doit être propagé à la resource provider."
  }
}

run "rejects_invalid_scope" {
  command = plan

  variables {
    name       = "bad-scope"
    public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBQqn0OHfSEwi1FfbxLFz9e3M+B4N/kd0aeGFRfxKlXa user@host"
    scope      = "admin"
  }

  expect_failures = [
    var.scope,
  ]
}
