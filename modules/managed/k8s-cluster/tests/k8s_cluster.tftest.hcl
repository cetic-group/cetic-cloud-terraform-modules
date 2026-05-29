# Tests natifs Terraform pour `managed/k8s-cluster`.

mock_provider "cetic-cloud-platform" {
  mock_resource "ccp_k8s_cluster" {
    defaults = {
      id                        = "00000000-0000-0000-0000-000000000010"
      status                    = "provisioning"
      tier                      = "dev"
      api_endpoint              = "10.20.1.10:6443"
      apiserver_internal_ip     = "10.20.1.10"
      ingress_internal_ip       = "10.20.1.11"
      ingress_public_ip_address = null
      public_ip_address         = null
      proxy_secondary_vmid      = null
      proxy_secondary_node      = null
      proxy_vip_vnet            = null
    }
  }

  mock_resource "ccp_k8s_node_pool" {
    defaults = {
      id = "00000000-0000-0000-0000-000000000020"
    }
  }
}

run "creates_dev_tier_by_default" {
  command = plan

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
    condition     = ccp_k8s_cluster.this.tier == "dev"
    error_message = "Le tier par défaut doit être `dev` (frontal d'exposition unique)."
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
