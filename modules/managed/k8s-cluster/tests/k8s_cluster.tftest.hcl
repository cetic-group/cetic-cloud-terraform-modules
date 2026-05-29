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

run "public_ip_id_passthrough_mutable_apiserver_attach" {
  command = plan

  variables {
    name            = "test-pubip"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    public_ip_id    = "00000000-0000-0000-0000-0000000000ef"
  }

  assert {
    condition     = ccp_k8s_cluster.this.public_ip_id == "00000000-0000-0000-0000-0000000000ef"
    error_message = "`public_ip_id` (mutable, attach apiserver sans ForceNew) doit être transmis au resource."
  }
}
