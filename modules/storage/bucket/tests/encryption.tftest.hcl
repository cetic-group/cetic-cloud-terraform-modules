mock_provider "ccp" {}

variables {
  name   = "acme-documents"
  region = "RNN"
}

run "defaut_sans_chiffrement_fournisseur" {
  command = plan
  assert {
    condition     = ccp_object_bucket.this.encryption_mode == "none"
    error_message = "Par défaut le mode doit être « none »."
  }
  assert {
    condition     = output.encryption_mode == "none"
    error_message = "L'output encryption_mode doit refléter la ressource."
  }
}

run "sse_c_transmis" {
  command = plan
  variables {
    encryption_mode = "sse_c"
  }
  assert {
    condition     = ccp_object_bucket.this.encryption_mode == "sse_c"
    error_message = "encryption_mode doit être transmis à la ressource."
  }
}

run "format_majuscules_refuse" {
  command = plan
  variables {
    encryption_mode = "SSE-C"
  }
  expect_failures = [var.encryption_mode]
}

run "format_vide_refuse" {
  command = plan
  variables {
    encryption_mode = ""
  }
  expect_failures = [var.encryption_mode]
}

run "format_chiffre_initial_refuse" {
  command = plan
  variables {
    encryption_mode = "1x"
  }
  expect_failures = [var.encryption_mode]
}

run "public_avec_cle_client_refuse" {
  command = plan
  variables {
    is_public       = true
    encryption_mode = "sse_c"
  }
  expect_failures = [ccp_object_bucket.this]
}

run "public_sans_chiffrement_accepte" {
  command = plan
  variables {
    is_public       = true
    encryption_mode = "none"
  }
  assert {
    condition     = ccp_object_bucket.this.is_public == true
    error_message = "Un bucket public sans clé client reste permis."
  }
}
