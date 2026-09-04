# Tests natifs Terraform pour le module `network/dns-zone`.
#
# Plan-only : le `mock_provider` intercepte tous les appels et rend des
# attributs synthétiques cohérents avec le schéma réel du provider.
#
# Lancer : `terraform test` depuis `modules/network/dns-zone/`.

mock_provider "ccp" {
  mock_resource "ccp_dns_zone" {
    defaults = {
      id                 = "00000000-0000-0000-0000-000000000001"
      region             = "RNN"
      status             = "active"
      resolver_status    = "active"
      ns_hostname        = "ns1.dns.example"
      resolver_addresses = ["10.20.0.51", "10.21.0.51"]
      resolver_endpoints = [
        {
          address   = "10.20.0.51"
          vnet_id   = "00000000-0000-0000-0000-0000000000a1"
          vnet_name = "bureau"
          vnet_cidr = "10.20.0.0/24"
        },
        {
          address   = "10.21.0.51"
          vnet_id   = "00000000-0000-0000-0000-0000000000a2"
          vnet_name = "atelier"
          vnet_cidr = "10.21.0.0/24"
        },
      ]
      applies_to_new_guests_only = true
      ownership_challenge        = null
    }
  }

  mock_resource "ccp_dns_record" {
    defaults = {
      id                = "00000000-0000-0000-0000-000000000010"
      is_system_managed = false
    }
  }
}

# ── 1. Zone seule, réglages laissés à la plateforme ───────────────────────────
run "zone_only_platform_defaults" {
  command = plan

  variables {
    name   = "corp.internal"
    vpc_id = "00000000-0000-0000-0000-0000000000ff"
  }

  assert {
    condition     = ccp_dns_zone.this.name == "corp.internal"
    error_message = "Le nom de la zone ne correspond pas à l'input."
  }

  # La zone appartient au RÉSEAU PRIVÉ, pas à un sous-réseau.
  assert {
    condition     = ccp_dns_zone.this.vpc_id == "00000000-0000-0000-0000-0000000000ff"
    error_message = "La zone doit être rattachée au réseau privé."
  }

  # Le module ne doit FIGER ni le niveau de service ni le TTL : leurs défauts
  # sont `null`, ce qui laisse vivre le réglage de la plateforme. Un défaut en
  # dur ici le rendrait mort — un exploitant qui le change ne verrait jamais
  # d'effet.
  #
  # C'est la variable qu'on assied, pas l'attribut : `tier` et `default_ttl`
  # sont Optional+Computed côté provider, donc inconnus au plan. Le câblage
  # `tier = var.tier`, lui, est couvert par le run suivant (« prod » est bien
  # transmis).
  assert {
    condition     = var.tier == null && var.default_ttl == null
    error_message = "tier et default_ttl doivent avoir null pour défaut, pas une valeur figée par le module."
  }

  assert {
    condition     = ccp_dns_zone.this.dnssec_enabled == false
    error_message = "dnssec_enabled doit valoir false par défaut."
  }

  assert {
    condition     = ccp_dns_zone.this.wait_for_verification == false
    error_message = "wait_for_verification doit valoir false par défaut : un apply n'attend pas un geste externe."
  }

  assert {
    condition     = length(ccp_dns_record.this) == 0
    error_message = "Aucun enregistrement ne doit être créé quand records est vide."
  }
}

# ── 2. Zone + enregistrements ────────────────────────────────────────────────
run "zone_with_records" {
  command = plan

  variables {
    name        = "corp.internal"
    vpc_id      = "00000000-0000-0000-0000-0000000000ff"
    tier        = "prod"
    default_ttl = 300

    records = {
      www = {
        name    = "www"
        type    = "A"
        ttl     = 300
        records = ["10.20.0.10", "10.20.0.11"]
      }
      apex_mx = {
        name    = "@"
        type    = "MX"
        records = ["10 mail.corp.internal."]
      }
    }
  }

  assert {
    condition     = ccp_dns_zone.this.tier == "prod"
    error_message = "tier n'est pas transmis."
  }

  assert {
    condition     = length(ccp_dns_record.this) == 2
    error_message = "Les deux enregistrements doivent être créés."
  }

  assert {
    condition     = ccp_dns_record.this["www"].type == "A" && ccp_dns_record.this["apex_mx"].type == "MX"
    error_message = "Le type de chaque enregistrement doit être transmis tel quel."
  }

  # L'ensemble des valeurs est envoyé entier — c'est le modèle de l'API.
  assert {
    condition     = length(ccp_dns_record.this["www"].records) == 2
    error_message = "Les valeurs du couple (nom, type) doivent partir en entier."
  }

  # `@` désigne l'apex : le module ne le réécrit pas.
  assert {
    condition     = ccp_dns_record.this["apex_mx"].name == "@"
    error_message = "Le nom saisi doit être transmis tel quel, la plateforme le qualifie."
  }

  # Un ttl précisé est transmis tel quel. Celui qu'on omet n'est PAS assertable
  # ici : `ttl` est Optional+Computed côté provider, donc inconnu au plan — le
  # défaut de 3600 n'apparaît qu'à l'apply.
  assert {
    condition     = ccp_dns_record.this["www"].ttl == 300
    error_message = "Un ttl précisé doit être transmis tel quel."
  }
}

# ── 3. `NS` est refusé — l'apex est en lecture seule, ailleurs c'est une
#       délégation qu'une zone privée refuse (422). Mieux vaut le dire au plan.
run "rejects_ns_record" {
  command = plan

  variables {
    name   = "corp.internal"
    vpc_id = "00000000-0000-0000-0000-0000000000ff"
    records = {
      deleg = {
        name    = "sub"
        type    = "NS"
        records = ["ns1.exemple.com."]
      }
    }
  }

  expect_failures = [var.records]
}

# ── 4. Un enregistrement sans valeur n'a pas de sens ─────────────────────────
run "rejects_empty_record_values" {
  command = plan

  variables {
    name   = "corp.internal"
    vpc_id = "00000000-0000-0000-0000-0000000000ff"
    records = {
      www = {
        name    = "www"
        type    = "A"
        records = []
      }
    }
  }

  expect_failures = [var.records]
}

# ── 5. Le TTL a un plancher et un plafond ────────────────────────────────────
run "rejects_out_of_range_ttl" {
  command = plan

  variables {
    name   = "corp.internal"
    vpc_id = "00000000-0000-0000-0000-0000000000ff"
    records = {
      www = {
        name    = "www"
        type    = "A"
        ttl     = 30
        records = ["10.20.0.10"]
      }
    }
  }

  expect_failures = [var.records]
}

# ── 6. Un tier inconnu est refusé au plan ────────────────────────────────────
run "rejects_unknown_tier" {
  command = plan

  variables {
    name   = "corp.internal"
    vpc_id = "00000000-0000-0000-0000-0000000000ff"
    tier   = "ha"
  }

  expect_failures = [var.tier]
}
