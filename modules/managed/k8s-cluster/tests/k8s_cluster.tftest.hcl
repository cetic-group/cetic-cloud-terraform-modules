# Tests natifs Terraform pour `managed/k8s-cluster`.

mock_provider "ccp" {
  mock_resource "ccp_k8s_cluster" {
    defaults = {
      id                        = "00000000-0000-0000-0000-000000000010"
      status                    = "provisioning"
      tier                      = "dev"
      plan                      = "starter"
      etcd_volume_gb            = 10
      node_ip_block_size        = 16
      current_k8s_version       = "v1.31.4"
      os_image                  = "flatcar"
      api_endpoint              = "10.20.1.10:6443"
      apiserver_internal_ip     = "10.20.1.10"
      ingress_internal_ip       = "10.20.1.11"
      ingress_public_ip_address = null
      public_ip_address         = null
      proxy_vip_vnet            = null
    }
  }

  mock_resource "ccp_k8s_node_pool" {
    defaults = {
      id          = "00000000-0000-0000-0000-000000000020"
      k8s_version = "v1.31.4"
    }
  }
}

run "creates_dev_tier_by_default" {
  # apply (provider mocké) : plan/tier/… sont calculés, inconnus au plan.
  command = apply

  variables {
    name            = "test-dev"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
  }

  assert {
    condition     = ccp_k8s_cluster.this.name == "test-dev"
    error_message = "Le nom doit refléter l'input."
  }

  assert {
    condition     = output.tier == "dev" && output.plan == "starter"
    error_message = "Sans plan ni tier, le cluster doit rester `starter` (tier `dev`, frontal d'exposition unique)."
  }
}

run "accepts_tier_prod" {
  command = plan

  variables {
    name            = "test-prod"
    region          = "RNN"
    tier            = "prod"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
  }

  assert {
    condition     = ccp_k8s_cluster.this.tier == "prod"
    error_message = "Le tier `prod` doit être propagé à la resource provider."
  }
}

run "rejects_invalid_tier" {
  command = plan

  variables {
    name            = "test-bad-tier"
    region          = "RNN"
    tier            = "staging"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
  }

  expect_failures = [
    var.tier,
  ]
}

run "rejects_invalid_region" {
  command = plan

  variables {
    name            = "test-bad-region"
    region          = "ZZZ"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
  }

  expect_failures = [
    var.region,
  ]
}

run "additional_pool_with_taints" {
  command = plan

  variables {
    name            = "test-taints"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    additional_pools = {
      gpu = {
        plan     = "xlarge"
        replicas = 1
        labels   = { workload = "gpu" }
        taints = [
          {
            key    = "nvidia.com/gpu"
            value  = "present"
            effect = "NoSchedule"
          },
        ]
      }
    }
  }

  assert {
    condition     = ccp_k8s_node_pool.additional["gpu"].taints == toset([{ key = "nvidia.com/gpu", value = "present", effect = "NoSchedule" }])
    error_message = "Les taints doivent être propagés au node pool."
  }
}

run "rejects_invalid_taint_effect" {
  command = plan

  variables {
    name            = "test-bad-taint"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    additional_pools = {
      bad = {
        plan     = "small"
        replicas = 1
        taints = [
          {
            key    = "foo"
            effect = "InvalidEffect"
          },
        ]
      }
    }
  }

  expect_failures = [
    var.additional_pools,
  ]
}

run "apiserver_public_ip_id_passthrough" {
  command = plan

  variables {
    name                   = "test-pubip"
    region                 = "RNN"
    vpc_id                 = "00000000-0000-0000-0000-0000000000aa"
    vnet_id                = "00000000-0000-0000-0000-0000000000bb"
    os_template_key        = "ubuntu-22.04"
    apiserver_public_ip_id = "00000000-0000-0000-0000-0000000000ef"
  }

  assert {
    condition     = ccp_k8s_cluster.this.apiserver_public_ip_id == "00000000-0000-0000-0000-0000000000ef"
    error_message = "`apiserver_public_ip_id` (unique levier mutable, provider v3) doit être transmis au resource."
  }
}

run "initial_pool_autoscaler_passthrough" {
  command = plan

  variables {
    name            = "test-asg"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    initial_pool = {
      name     = "default"
      plan     = "small"
      replicas = 2
      min_size = 2
      max_size = 5
    }
  }

  assert {
    condition     = ccp_k8s_cluster.this.initial_pool.min_size == 2
    error_message = "min_size de l'initial_pool doit être propagé au provider."
  }
  assert {
    condition     = ccp_k8s_cluster.this.initial_pool.max_size == 5
    error_message = "max_size de l'initial_pool doit être propagé au provider."
  }
}

run "initial_pool_rejects_min_without_max" {
  command = plan

  variables {
    name            = "test-asg-bad"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    initial_pool = {
      min_size = 2
    }
  }

  expect_failures = [var.initial_pool]
}

run "initial_pool_rejects_max_le_min" {
  command = plan

  variables {
    name            = "test-asg-bad2"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    initial_pool = {
      min_size = 5
      max_size = 3
    }
  }

  expect_failures = [var.initial_pool]
}

run "initial_pool_labels_and_taints_passthrough" {
  command = plan

  variables {
    name            = "test-lt"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    initial_pool = {
      name     = "default"
      plan     = "small"
      replicas = 2
      labels   = { "cetic-group.com/workload" = "app" }
      taints = [
        { key = "dedicated", value = "app", effect = "NoSchedule" },
      ]
    }
  }

  assert {
    condition     = ccp_k8s_cluster.this.initial_pool.labels["cetic-group.com/workload"] == "app"
    error_message = "Les labels de l'initial_pool doivent être propagés au provider."
  }
  assert {
    condition     = one(ccp_k8s_cluster.this.initial_pool.taints).effect == "NoSchedule"
    error_message = "Les taints de l'initial_pool doivent être propagés au provider."
  }
}

run "initial_pool_rejects_invalid_taint_effect" {
  command = plan

  variables {
    name            = "test-lt-bad"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    initial_pool = {
      taints = [
        { key = "x", effect = "BogusEffect" },
      ]
    }
  }

  expect_failures = [var.initial_pool]
}

run "os_image_passthrough" {
  command = plan

  variables {
    name            = "test-os-image"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    os_image        = "ubuntu"
  }

  assert {
    condition     = ccp_k8s_cluster.this.os_image == "ubuntu"
    error_message = "La famille d'OS des nodes (os_image) doit être transmise au resource."
  }
}

run "rejects_invalid_os_image" {
  command = plan

  variables {
    name            = "test-bad-os-image"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    os_image        = "windows"
  }

  expect_failures = [var.os_image]
}

run "initial_pool_k8s_version_passthrough" {
  command = plan

  variables {
    name            = "test-ip-ver"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    k8s_version     = "v1.31.4"
    initial_pool = {
      name        = "default"
      plan        = "small"
      replicas    = 2
      k8s_version = "v1.30.4"
    }
  }

  assert {
    condition     = ccp_k8s_cluster.this.initial_pool.k8s_version == "v1.30.4"
    error_message = "La version worker de l'initial_pool doit être transmise au provider."
  }
}

run "additional_pool_k8s_version_passthrough" {
  command = plan

  variables {
    name            = "test-ap-ver"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    k8s_version     = "v1.31.4"
    additional_pools = {
      older = {
        plan        = "medium"
        replicas    = 2
        k8s_version = "v1.30.4"
      }
    }
  }

  assert {
    condition     = ccp_k8s_node_pool.additional["older"].k8s_version == "v1.30.4"
    error_message = "La version worker d'un pool additionnel doit être transmise au node pool."
  }
}

run "initial_pool_disk_gb_passthrough" {
  command = plan

  variables {
    name            = "test-ip-disk"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    initial_pool = {
      name     = "default"
      plan     = "small"
      replicas = 2
      disk_gb  = 100
    }
  }

  assert {
    condition     = ccp_k8s_cluster.this.initial_pool.disk_gb == 100
    error_message = "La taille de disque de l'initial_pool doit être transmise au provider."
  }
}

run "additional_pool_disk_gb_passthrough" {
  command = plan

  variables {
    name            = "test-ap-disk"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    additional_pools = {
      big_disk = {
        plan     = "medium"
        replicas = 2
        disk_gb  = 200
      }
    }
  }

  assert {
    condition     = ccp_k8s_node_pool.additional["big_disk"].disk_gb == 200
    error_message = "La taille de disque d'un pool additionnel doit être transmise au node pool."
  }
}

# ─── plan / tier (cetic-cloud-platform#2143, provider >= 7.6.0) ──────────────

run "tier_not_sent_by_default" {
  # apply (provider mocké) : plan/tier/… sont calculés, inconnus au plan.
  command = apply

  variables {
    name            = "tier-not-sent-by-default"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
  }

  assert {
    condition     = var.tier == null && var.plan == null
    error_message = "Sans tier ni plan, rien n'est transmis : le provider garde le plan courant (starter à la création)."
  }
  assert {
    condition     = output.plan == "starter"
    error_message = "L'output plan doit refléter le plan effectif du provider."
  }
}

run "plan_passthrough" {
  command = plan

  variables {
    name            = "plan-passthrough"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    plan            = "pro"
  }

  assert {
    condition     = ccp_k8s_cluster.this.plan == "pro"
    error_message = "plan doit être transmis à la resource provider."
  }
}

run "rejects_invalid_plan" {
  command = plan

  variables {
    name            = "rejects-invalid-plan"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    plan            = "enterprise"
  }

  expect_failures = [var.plan]
}

run "accepts_plan_and_tier_consistent" {
  command = plan

  variables {
    name            = "accepts-plan-and-tier-consiste"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    plan            = "standard"
    tier            = "prod"
  }

  assert {
    condition     = ccp_k8s_cluster.this.plan == "standard" && ccp_k8s_cluster.this.tier == "prod"
    error_message = "plan et tier cohérents doivent être transmis tels quels."
  }
}

run "rejects_paid_plan_with_tier_dev" {
  command = plan

  variables {
    name            = "rejects-paid-plan-with-tier-de"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    plan            = "pro"
    tier            = "dev"
  }

  expect_failures = [ccp_k8s_cluster.this]
}

run "rejects_starter_with_tier_prod" {
  command = plan

  variables {
    name            = "rejects-starter-with-tier-prod"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    plan            = "starter"
    tier            = "prod"
  }

  expect_failures = [ccp_k8s_cluster.this]
}

run "computed_outputs" {
  # apply (provider mocké) : plan/tier/… sont calculés, inconnus au plan.
  command = apply

  variables {
    name            = "computed-outputs"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
  }

  assert {
    condition     = output.etcd_volume_gb == 10 && output.node_ip_block_size == 16
    error_message = "etcd_volume_gb et node_ip_block_size doivent être exposés."
  }
  assert {
    condition     = output.current_k8s_version == "v1.31.4"
    error_message = "current_k8s_version doit être exposé."
  }
}

# ─── maintenance / oidc ──────────────────────────────────────────────────────

run "maintenance_passthrough" {
  command = plan

  variables {
    name            = "maintenance-passthrough"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    maintenance = {
      auto_mineure = true
      fenetre = {
        jours        = [6, 7]
        heure_debut  = "02:00"
        duree_heures = 6
        fuseau       = "Europe/Paris"
      }
      dates_gel = [{ debut = "2026-12-20", fin = "2027-01-03" }]
    }
  }

  assert {
    condition     = ccp_k8s_cluster.this.maintenance.auto_mineure == true
    error_message = "maintenance.auto_mineure doit être transmis."
  }
  assert {
    condition     = ccp_k8s_cluster.this.maintenance.fenetre.heure_debut == "02:00"
    error_message = "maintenance.fenetre doit être transmise."
  }
  assert {
    condition     = ccp_k8s_cluster.this.maintenance.dates_gel[0].fin == "2027-01-03"
    error_message = "maintenance.dates_gel doit être transmis."
  }
}

run "rejects_invalid_maintenance_window" {
  command = plan

  variables {
    name            = "rejects-invalid-maintenance-wi"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    maintenance = {
      fenetre = {
        jours        = [0]
        heure_debut  = "25:00"
        duree_heures = 2
        fuseau       = "Europe/Paris"
      }
    }
  }

  expect_failures = [var.maintenance]
}

run "rejects_invalid_freeze_date" {
  command = plan

  variables {
    name            = "rejects-invalid-freeze-date"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    maintenance = {
      dates_gel = [{ debut = "20/12/2026", fin = "2027-01-03" }]
    }
  }

  expect_failures = [var.maintenance]
}

run "oidc_passthrough" {
  command = plan

  variables {
    name            = "oidc-passthrough"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    oidc = {
      issuer_url   = "https://sso.example.com/realms/acme"
      client_id    = "kubernetes"
      groups_claim = ""
    }
  }

  assert {
    condition     = ccp_k8s_cluster.this.oidc.client_id == "kubernetes"
    error_message = "oidc doit être transmis."
  }
  assert {
    # Le provider mocké n'applique pas ses défauts (`email`) : on vérifie que le
    # module n'impose aucune valeur et laisse le défaut au provider.
    condition     = ccp_k8s_cluster.this.oidc.username_claim == null && ccp_k8s_cluster.this.oidc.groups_claim == ""
    error_message = "Un champ oidc omis ne doit pas être forcé par le module ; un champ écrit est transmis tel quel."
  }
}

run "rejects_oidc_without_https" {
  command = plan

  variables {
    name            = "rejects-oidc-without-https"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    oidc = {
      issuer_url = "http://sso.example.com"
      client_id  = "kubernetes"
    }
  }

  expect_failures = [var.oidc]
}

run "oidc_null_by_default" {
  command = plan

  variables {
    name            = "oidc-null-by-default"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
  }

  assert {
    condition     = ccp_k8s_cluster.this.oidc == null
    error_message = "Sans variable oidc, aucun SSO ne doit être configuré."
  }
}
