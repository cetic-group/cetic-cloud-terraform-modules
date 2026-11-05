mock_provider "ccp" {}

variables {
  name   = "acme-uploads"
  region = "RNN"
}

run "sans_cors" {
  command = plan
  assert {
    condition     = length(ccp_object_bucket.this.cors_rule) == 0
    error_message = "Sans cors_rules, aucun bloc ne doit être envoyé."
  }
}

run "regles_transmises" {
  command = plan
  variables {
    cors_rules = [
      { allowed_origins = ["https://app.example.com"], allowed_methods = ["PUT", "POST"], allowed_headers = ["Content-Type"] },
      { allowed_origins = ["https://app.example.com"], allowed_methods = ["GET"], max_age_seconds = 600 },
    ]
  }
  assert {
    condition     = length(ccp_object_bucket.this.cors_rule) == 2
    error_message = "Les deux règles doivent être transmises, dans l'ordre."
  }
}

run "methode_invalide" {
  command = plan
  variables {
    cors_rules = [{ allowed_origins = ["https://a.example.com"], allowed_methods = ["PATCH"] }]
  }
  expect_failures = [var.cors_rules]
}

run "origine_absente" {
  command = plan
  variables {
    cors_rules = [{ allowed_origins = [], allowed_methods = ["GET"] }]
  }
  expect_failures = [var.cors_rules]
}
