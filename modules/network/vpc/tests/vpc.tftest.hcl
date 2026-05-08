# Tests natifs Terraform pour le module `network/vpc`.
#
# Plan-only : on valide que le rendering est correct sans toucher à l'API CETIC
# Cloud. Les `mock_provider` interceptent tous les appels et renvoient des
# attributs synthétiques cohérents avec le schéma du provider réel.
#
# Lancer : `terraform test` depuis ce dossier (`modules/network/vpc/`).

mock_provider "ccp" {
  mock_resource "ccp_vpc" {
    defaults = {
      id       = "00000000-0000-0000-0000-000000000001"
      status   = "active"
      vlan_id  = 100
      sdn_type = "vxlan"
    }
  }

  mock_resource "ccp_vnet" {
    defaults = {
      id         = "00000000-0000-0000-0000-000000000010"
      gateway    = "10.0.1.1"
      dhcp_start = "10.0.1.51"
      dhcp_end   = "10.0.1.254"
      isolated   = false
      status     = "active"
    }
  }

  mock_resource "ccp_vnet_ip_reservation" {
    defaults = {
      id       = "00000000-0000-0000-0000-000000000020"
      ip_count = 1
      kind     = "single"
    }
  }

  mock_resource "ccp_vnet_firewall_rule" {
    defaults = {
      id = "00000000-0000-0000-0000-000000000030"
    }
  }

}

# ── 1. VPC vide (sans VNet) ───────────────────────────────────────────────────
run "vpc_only_no_vnets" {
  command = plan

  variables {
    name   = "test-vpc"
    region = "RNN"
    tags   = ["env:test"]
  }

  assert {
    condition     = ccp_vpc.this.name == "test-vpc"
    error_message = "Le nom du VPC ne correspond pas à l'input."
  }

  assert {
    condition     = ccp_vpc.this.region == "RNN"
    error_message = "La région du VPC ne correspond pas à l'input."
  }

  assert {
    condition     = length(ccp_vnet.this) == 0
    error_message = "Aucun VNet ne devrait être créé quand `vnets = {}`."
  }
}

# ── 2. VPC + 2 VNets simples ──────────────────────────────────────────────────
run "vpc_with_two_vnets" {
  command = plan

  variables {
    name   = "twonets"
    region = "PAR"

    vnets = {
      web = {
        cidr = "10.0.1.0/24"
        snat = true
      }
      data = {
        cidr = "10.0.2.0/24"
        snat = true
      }
    }
  }

  assert {
    condition     = length(ccp_vnet.this) == 2
    error_message = "Deux VNets devraient être créés."
  }

  assert {
    condition     = ccp_vnet.this["web"].cidr == "10.0.1.0/24"
    error_message = "Le CIDR du VNet `web` doit être 10.0.1.0/24."
  }

  assert {
    condition     = ccp_vnet.this["data"].cidr == "10.0.2.0/24"
    error_message = "Le CIDR du VNet `data` doit être 10.0.2.0/24."
  }

  assert {
    condition     = ccp_vnet.this["web"].snat == true
    error_message = "SNAT doit être activé sur le VNet web."
  }
}

# ── 3. VNet avec firewall rules + position auto-incrémentée ───────────────────
run "vnet_with_firewall_rules_auto_position" {
  command = plan

  variables {
    name   = "fwtest"
    region = "RNN"

    vnets = {
      web = {
        cidr = "10.0.1.0/24"
        snat = true
        firewall_rules = [
          { direction = "in", protocol = "tcp", source_cidr = "0.0.0.0/0", port = "80", description = "HTTP" },
          { direction = "in", protocol = "tcp", source_cidr = "0.0.0.0/0", port = "443", description = "HTTPS" },
          { direction = "in", protocol = "tcp", source_cidr = "10.99.0.0/24", port = "22", description = "SSH ops" },
        ]
      }
    }
  }

  assert {
    condition     = length(ccp_vnet_firewall_rule.this) == 3
    error_message = "Trois règles firewall doivent être créées."
  }

  assert {
    condition     = ccp_vnet_firewall_rule.this["web:0"].position == 10
    error_message = "La 1re règle doit avoir position=10 (auto-increment)."
  }

  assert {
    condition     = ccp_vnet_firewall_rule.this["web:1"].position == 20
    error_message = "La 2e règle doit avoir position=20 (auto-increment)."
  }

  assert {
    condition     = ccp_vnet_firewall_rule.this["web:2"].position == 30
    error_message = "La 3e règle doit avoir position=30 (auto-increment)."
  }

  assert {
    condition     = ccp_vnet_firewall_rule.this["web:0"].direction == "IN"
    error_message = "La direction doit être uppercased à `IN`."
  }

  assert {
    condition     = ccp_vnet_firewall_rule.this["web:0"].action == "ACCEPT"
    error_message = "L'action doit toujours être ACCEPT (les rules de DROP sont implicites quand isolated=true)."
  }
}

# ── 4. IP reservations dans un VNet ───────────────────────────────────────────
run "vnet_with_ip_reservations" {
  command = plan

  variables {
    name   = "ipreservtest"
    region = "RNN"

    vnets = {
      data = {
        cidr = "10.0.2.0/24"
        snat = true
        ip_reservations = {
          pg_primary = { ip = "10.0.2.10", description = "PG primary" }
          pg_replica = { ip = "10.0.2.11" }
        }
      }
    }
  }

  assert {
    condition     = length(ccp_vnet_ip_reservation.this) == 2
    error_message = "Deux IP reservations doivent être créées."
  }

  assert {
    condition     = ccp_vnet_ip_reservation.this["data:pg_primary"].ip == "10.0.2.10"
    error_message = "L'IP réservée pour pg_primary doit être 10.0.2.10."
  }

  assert {
    condition     = ccp_vnet_ip_reservation.this["data:pg_primary"].description == "PG primary"
    error_message = "La description doit être propagée."
  }

  assert {
    condition     = ccp_vnet_ip_reservation.this["data:pg_primary"].name == "pg_primary"
    error_message = "Le `name` de la réservation doit être la clé de la map."
  }
}

# ── 5. Validation : CIDR invalide → plan échoue ───────────────────────────────
run "rejects_invalid_cidr" {
  command = plan

  variables {
    name   = "bad-cidr"
    region = "RNN"
    vnets = {
      bad = {
        cidr = "not-a-cidr"
      }
    }
  }

  expect_failures = [
    var.vnets,
  ]
}

# ── 6. Validation : région invalide → plan échoue ─────────────────────────────
run "rejects_invalid_region" {
  command = plan

  variables {
    name   = "bad-region"
    region = "EUW1"
  }

  expect_failures = [
    var.region,
  ]
}

# ── 7. Outputs cohérents pour utilisation downstream ──────────────────────────
run "outputs_are_indexed_by_logical_key" {
  command = plan

  variables {
    name   = "outputs-test"
    region = "RNN"
    vnets = {
      web = { cidr = "10.0.1.0/24", snat = true }
      api = { cidr = "10.0.2.0/24", snat = true }
    }
  }

  assert {
    condition     = contains(keys(output.vnet_ids), "web")
    error_message = "L'output `vnet_ids` doit contenir la clé `web`."
  }

  assert {
    condition     = contains(keys(output.vnet_ids), "api")
    error_message = "L'output `vnet_ids` doit contenir la clé `api`."
  }

  assert {
    condition     = output.vnets["web"].cidr == "10.0.1.0/24"
    error_message = "L'output `vnets[\"web\"].cidr` doit refléter l'input."
  }
}

# ── 8. (retiré en v0.3.0) — peering est maintenant via `modules/network/vnet-peering` ─
