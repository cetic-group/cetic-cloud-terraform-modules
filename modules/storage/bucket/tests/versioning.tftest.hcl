mock_provider "ccp" {}

variables {
  name   = "acme-documents"
  region = "RNN"
}

run "sans_versioning" {
  command = plan
  assert {
    condition     = ccp_object_bucket.this.versioning == null
    error_message = "Sans versioning, aucun bloc ne doit être envoyé (versionnage non géré)."
  }
}

run "versioning_transmis" {
  command = plan
  variables {
    versioning = { status = "Enabled", noncurrent_version_expiration_days = 90 }
  }
  assert {
    condition     = ccp_object_bucket.this.versioning.status == "Enabled"
    error_message = "Le statut doit être transmis."
  }
  assert {
    condition     = ccp_object_bucket.this.versioning.noncurrent_version_expiration_days == 90
    error_message = "La durée doit être transmise."
  }
}

run "suspendu_sans_duree" {
  command = plan
  variables {
    versioning = { status = "Suspended" }
  }
  assert {
    condition     = ccp_object_bucket.this.versioning.status == "Suspended"
    error_message = "Suspended doit être transmis tel quel."
  }
}

run "desactive_refuse" {
  command = plan
  variables {
    versioning = { status = "Disabled" }
  }
  expect_failures = [var.versioning]
}

run "duree_nulle_refusee" {
  command = plan
  variables {
    versioning = { status = "Enabled", noncurrent_version_expiration_days = 0 }
  }
  expect_failures = [var.versioning]
}

run "duree_trop_longue_refusee" {
  command = plan
  variables {
    versioning = { status = "Enabled", noncurrent_version_expiration_days = 3651 }
  }
  expect_failures = [var.versioning]
}

run "duree_fractionnaire_refusee" {
  command = plan
  variables {
    versioning = { status = "Enabled", noncurrent_version_expiration_days = 2.5 }
  }
  expect_failures = [var.versioning]
}

run "bornes_acceptees" {
  command = plan
  variables {
    versioning = { status = "Enabled", noncurrent_version_expiration_days = 3650 }
  }
  assert {
    condition     = ccp_object_bucket.this.versioning.noncurrent_version_expiration_days == 3650
    error_message = "3650 jours est la borne haute acceptée."
  }
}
