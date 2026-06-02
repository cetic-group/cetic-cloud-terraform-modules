# Tests natifs Terraform pour le module `network/public-ip`.
#
# Plan-only : `mock_provider` intercepte les appels API. On valide le rendering
# (quantité, suffixage du label, validations) sans toucher à l'API CETIC Cloud.
#
# Lancer : `terraform test` depuis `modules/network/public-ip/`.

mock_provider "ccp" {
  mock_resource "ccp_public_ip" {
    defaults = {
      id         = "00000000-0000-0000-0000-0000000000c1"
      ip_address = "203.0.113.10"
      status     = "available"
    }
  }
}

# ── 1. Défaut : quantity=1, label null ────────────────────────────────────────
run "default_single_no_label" {
  command = plan

  variables {
    region = "RNN"
  }

  assert {
    condition     = length(ccp_public_ip.this) == 1
    error_message = "Par défaut, une seule IP doit être allouée."
  }

  assert {
    condition     = ccp_public_ip.this[0].label == null
    error_message = "Sans label, l'attribut doit rester null."
  }

  assert {
    condition     = ccp_public_ip.this[0].region == "RNN"
    error_message = "La région doit être propagée."
  }
}

# ── 2. Label set, quantity=1 → pas de suffixe ─────────────────────────────────
run "single_with_label_no_suffix" {
  command = plan

  variables {
    region = "RNN"
    label  = "passerelle-prod"
  }

  assert {
    condition     = ccp_public_ip.this[0].label == "passerelle-prod"
    error_message = "Avec quantity=1, le label ne doit PAS être suffixé."
  }
}

# ── 3. quantity=3 → labels suffixés -1 / -2 / -3 ──────────────────────────────
run "multiple_labels_suffixed" {
  command = plan

  variables {
    region   = "RNN"
    quantity = 3
    label    = "ip-fixe-api"
  }

  assert {
    condition     = length(ccp_public_ip.this) == 3
    error_message = "Trois IPs doivent être allouées."
  }

  assert {
    condition     = ccp_public_ip.this[0].label == "ip-fixe-api-1"
    error_message = "La 1re IP doit avoir le label suffixé -1."
  }

  assert {
    condition     = ccp_public_ip.this[2].label == "ip-fixe-api-3"
    error_message = "La 3e IP doit avoir le label suffixé -3."
  }
}

# ── 4. quantity=9 → hors plage [1,8] → échec de validation ────────────────────
run "rejects_quantity_over_8" {
  command = plan

  variables {
    region   = "RNN"
    quantity = 9
  }

  expect_failures = [
    var.quantity,
  ]
}
