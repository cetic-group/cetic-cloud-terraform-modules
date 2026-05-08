# Tests natifs Terraform pour `atomic/ssh-key`.

mock_provider "ccp" {
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
