mock_provider "ccp" {}

variables {
  name   = "acme-documents"
  region = "RNN"
}

run "defaut_null_omet_l_attribut" {
  command = plan
  assert {
    condition     = var.encryption_mode == null
    error_message = "Par défaut la variable doit valoir null."
  }
}

run "output_reflete_l_attribut_de_la_ressource" {
  command = apply
  override_resource {
    target = ccp_object_bucket.this
    values = {
      encryption_mode = "sse_c"
    }
  }
  assert {
    condition     = output.encryption_mode == "sse_c"
    error_message = "L'output doit refléter l'attribut de la ressource, pas la variable."
  }
}

run "null_explicite_accepte" {
  command = plan
  variables {
    encryption_mode = null
  }
  assert {
    condition     = var.encryption_mode == null
    error_message = "null doit être accepté."
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
  assert {
    condition     = output.encryption_mode == "sse_c"
    error_message = "L'output encryption_mode doit valoir sse_c."
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

run "public_avec_null_accepte" {
  command = plan
  variables {
    is_public       = true
    encryption_mode = null
  }
  assert {
    condition     = ccp_object_bucket.this.is_public == true
    error_message = "Public avec encryption_mode null doit rester permis."
  }
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

run "is_public_null_avec_sse_c_tolere" {
  command = plan
  variables {
    is_public       = null
    encryption_mode = "sse_c"
  }
  assert {
    condition     = ccp_object_bucket.this.encryption_mode == "sse_c"
    error_message = "is_public = null ne doit pas faire échouer la garde."
  }
}

run "is_public_null_sans_chiffrement_tolere" {
  command = plan
  variables {
    is_public = null
  }
  assert {
    condition     = var.encryption_mode == null
    error_message = "is_public = null ne doit pas faire échouer la garde."
  }
}
