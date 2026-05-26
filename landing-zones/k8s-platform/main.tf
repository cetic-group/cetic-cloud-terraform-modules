locals {
  base_tags = concat(
    [
      "landing-zone:k8s-platform",
      "org:${var.org_prefix}",
      "region:${var.region}",
    ],
    var.tags_extra,
  )

  vpc_name     = "${var.org_prefix}-${lower(var.region)}-vpc"
  cluster_name = "${var.org_prefix}-${lower(var.region)}-k8s"
}

# ─── Réseau (VPC + 2 VNets : workers + data) ─────────────────────────────────
module "vpc" {
  source = "../../modules/network/vpc"

  name   = local.vpc_name
  region = var.region
  tags   = local.base_tags

  vnets = {
    workers = {
      cidr = "10.20.1.0/24"
      snat = true
      tags = concat(["tier:k8s-workers"], local.base_tags)
    }
    data = {
      cidr = "10.20.2.0/24"
      snat = true
      tags = concat(["tier:data"], local.base_tags)
    }
  }
}

# ─── IP publique optionnelle pour l'apiserver ────────────────────────────────
resource "ccp_public_ip" "apiserver" {
  count  = var.expose_apiserver_publicly ? 1 : 0
  region = var.region
}

# ─── Cluster Kubernetes managé ────────────────────────────────────────────────
module "k8s" {
  source = "../../modules/managed/k8s-cluster"

  name        = local.cluster_name
  region      = var.region
  tier        = var.k8s_tier
  vpc_id      = module.vpc.vpc_id
  vnet_id     = module.vpc.vnet_ids.workers
  k8s_version = var.k8s_version

  initial_pool = {
    name     = "default"
    plan     = var.initial_pool_plan
    replicas = var.initial_pool_replicas
  }

  additional_pools = var.additional_pools

  ingress_controller_enabled = true
  ingress_controller_scope   = var.ingress_scope
  ingress_controller_class   = "incluster"

  apiserver_public_ip_id = var.expose_apiserver_publicly ? ccp_public_ip.apiserver[0].id : null

  tags = local.base_tags
}

# ─── Database optionnelle ────────────────────────────────────────────────────
module "database" {
  count  = var.enable_database ? 1 : 0
  source = "../../modules/managed/database/pg"

  name           = "${local.cluster_name}-db"
  region         = var.region
  vpc_id         = module.vpc.vpc_id
  vnet_id        = module.vpc.vnet_ids.data
  plan           = var.db_plan
  replicas       = var.db_replicas
  storage_gb     = var.db_storage_gb
  engine_version = "16"
  tags           = concat(["role:db"], local.base_tags)
}
