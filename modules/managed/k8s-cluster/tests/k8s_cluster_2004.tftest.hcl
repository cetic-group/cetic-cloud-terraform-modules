# Tests de cetic-cloud-platform#2004 : format de version, clé du template
# dérivée et lue à la création seulement. Fichier séparé : chaque fichier de
# test a son propre état, et ces exécutions ne doivent pas hériter de l'état
# laissé par les `apply` de k8s_cluster.tftest.hcl (`ignore_changes` y
# garderait la clé de l'apply précédent).

variables {
  k8s_version = "1.34.8"
}

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
      k8s_version = "1.34.8"
    }
  }
}

run "rejects_version_with_v_prefix" {
  command = plan

  variables {
    name            = "test-v"
    region          = "RNN"
    vpc_id          = "00000000-0000-0000-0000-0000000000aa"
    vnet_id         = "00000000-0000-0000-0000-0000000000bb"
    os_template_key = "ubuntu-22.04"
    k8s_version     = "v1.34.8"
  }

  expect_failures = [var.k8s_version]
}


run "derives_template_key_from_version" {
  command = plan

  variables {
    name    = "test-cle"
    region  = "RNN"
    vpc_id  = "00000000-0000-0000-0000-0000000000aa"
    vnet_id = "00000000-0000-0000-0000-0000000000bb"
  }

  assert {
    condition     = ccp_k8s_cluster.this.os_template_key == "kube-v1-34-8"
    error_message = "Sans os_template_key, la clé doit être dérivée de k8s_version (forme réécrite par l'API)."
  }
}

run "rejects_pool_version_with_v_prefix" {
  command = plan

  variables {
    name    = "test-pool-v"
    region  = "RNN"
    vpc_id  = "00000000-0000-0000-0000-0000000000aa"
    vnet_id = "00000000-0000-0000-0000-0000000000bb"
    initial_pool = {
      k8s_version = "v1.30.4"
    }
  }

  expect_failures = [var.initial_pool]
}

# Montée de version : la clé dérivée change avec `k8s_version`, mais le module
# l'ignore après la création (`ignore_changes`). Sans cela, le plan de la
# montée affichait `os_template_key` « forces replacement » et recréait le
# cluster (revue de cetic-cloud-terraform-modules#63). Les deux exécutions
# partagent l'état : la première crée, la seconde monte de version.
run "upgrade_creates_cluster" {
  command = apply

  variables {
    name        = "test-montee"
    region      = "RNN"
    vpc_id      = "00000000-0000-0000-0000-0000000000aa"
    vnet_id     = "00000000-0000-0000-0000-0000000000bb"
    k8s_version = "1.34.8"
  }
}

run "upgrade_keeps_template_key" {
  command = plan

  variables {
    name        = "test-montee"
    region      = "RNN"
    vpc_id      = "00000000-0000-0000-0000-0000000000aa"
    vnet_id     = "00000000-0000-0000-0000-0000000000bb"
    k8s_version = "1.35.0"
  }

  assert {
    condition     = ccp_k8s_cluster.this.k8s_version == "1.35.0"
    error_message = "La montée doit planifier la nouvelle version."
  }

  assert {
    condition     = ccp_k8s_cluster.this.os_template_key == "kube-v1-34-8"
    error_message = "La clé du template ne doit pas suivre la montée (sinon le cluster est recréé)."
  }
}
