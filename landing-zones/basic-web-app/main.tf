locals {
  base_tags = concat(
    [
      "landing-zone:basic-web-app",
      "org:${var.org_prefix}",
      "region:${var.region}",
    ],
    var.tags_extra,
  )

  vpc_name = "${var.org_prefix}-${lower(var.region)}-vpc"

  # Génération des noms d'instances : <prefix>-<region>-app-01, -02, …
  app_instance_names = [for i in range(var.app_replicas) : format("%s-%s-app-%02d", var.org_prefix, lower(var.region), i + 1)]
}

# ─── Identité (clé SSH ops) ───────────────────────────────────────────────────
module "ssh_key" {
  source = "../../modules/atomic/ssh-key"

  name       = "${var.org_prefix}-${lower(var.region)}-ops"
  public_key = var.ssh_public_key
}

# ─── Réseau (VPC + 2 VNets : web + data) ──────────────────────────────────────
module "vpc" {
  source = "../../modules/network/vpc"

  name   = local.vpc_name
  region = var.region
  tags   = local.base_tags

  vnets = {
    web = {
      cidr = "10.0.1.0/24"
      snat = true
      tags = concat(["tier:web"], local.base_tags)
      firewall_rules = concat(
        [
          { direction = "in", protocol = "tcp", source_cidr = "0.0.0.0/0", port = "80", description = "HTTP public" },
        ],
        var.expose_https ? [
          { direction = "in", protocol = "tcp", source_cidr = "0.0.0.0/0", port = "443", description = "HTTPS public" },
        ] : [],
      )
    }

    data = {
      cidr = "10.0.2.0/24"
      snat = true
      tags = concat(["tier:data"], local.base_tags)
      firewall_rules = [
        { direction = "in", protocol = "tcp", source_cidr = "10.0.1.0/24", port = "5432", description = "PG depuis web tier" },
      ]
    }
  }
}

# ─── Compute (N containers individuels, pour pouvoir les attacher au LB) ──────
resource "ccp_container_instance" "app" {
  provider = ccp
  for_each = toset(local.app_instance_names)

  name          = each.value
  region        = var.region
  plan          = var.app_plan
  template      = var.app_template
  vnet_id       = module.vpc.vnet_ids.web
  ssh_key_ids   = [module.ssh_key.id]
  root_password = var.app_root_password
  disk_gb       = var.app_disk_gb
  tags          = concat(["app:web"], local.base_tags)
}

# ─── Exposition publique ──────────────────────────────────────────────────────
# Une seule IP publique, partagée entre les deux modes d'exposition.
resource "ccp_public_ip" "exposure" {
  provider = ccp
  region   = var.region
}

# Mode "lb" — Load Balancer L4 (rétrocompat)
resource "ccp_load_balancer" "this" {
  provider = ccp
  count    = var.exposure_type == "lb" ? 1 : 0

  name         = "${var.org_prefix}-${lower(var.region)}-lb"
  region       = var.region
  plan         = var.lb_plan
  vnet_id      = module.vpc.vnet_ids.web
  public_ip_id = ccp_public_ip.exposure.id
  tags         = local.base_tags

  listener {
    protocol    = "http"
    listen_port = 80
    algorithm   = "roundrobin"

    dynamic "backend" {
      for_each = ccp_container_instance.app
      content {
        container_id = backend.value.id
        port         = var.app_listen_port
        weight       = 1
      }
    }
  }

  dynamic "listener" {
    for_each = var.expose_https ? [1] : []
    content {
      protocol    = "tcp"
      listen_port = 443
      algorithm   = "roundrobin"

      dynamic "backend" {
        for_each = ccp_container_instance.app
        content {
          container_id = backend.value.id
          port         = var.app_listen_port
        }
      }
    }
  }
}

# Mode "appgw" — Application Gateway L7
locals {
  appgw_hostname_effective = var.appgw_hostname != null ? var.appgw_hostname : "${var.org_prefix}-${lower(var.region)}.app.cloud.cetic-group.com"
}

module "appgw" {
  count = var.exposure_type == "appgw" ? 1 : 0

  source = "../../modules/exposure/web-app-with-appgw"

  name         = "${var.org_prefix}-${lower(var.region)}-appgw"
  region       = var.region
  plan         = var.appgw_plan
  vpc_id       = module.vpc.vpc_id
  vnet_id      = module.vpc.vnet_ids.web
  public_ip_id = ccp_public_ip.exposure.id
  tags         = local.base_tags

  hostnames            = [local.appgw_hostname_effective]
  acme_challenge       = var.appgw_acme_challenge
  acme_dns_provider    = var.appgw_acme_dns_provider
  acme_dns_credentials = var.appgw_acme_dns_credentials

  force_https               = true
  hsts_enabled              = var.appgw_hsts_enabled
  global_rate_limit_per_sec = var.appgw_rate_limit_per_sec

  target_groups = {
    default = {
      algorithm = "roundrobin"
      health_check = {
        protocol      = "http"
        path          = "/"
        expect_status = 200
        interval_sec  = 5
      }
      members = {
        for k, v in ccp_container_instance.app : k => {
          container_id = v.id
          port         = var.app_listen_port
          weight       = 100
        }
      }
    }
  }

  routes = [
    {
      listener_index   = 0
      target_group_key = "default"
      priority         = 100
      path_match       = "/"
      path_match_type  = "prefix"
    },
  ]
}

# ─── Base de données managée (PostgreSQL) ─────────────────────────────────────
resource "ccp_db_pg_instance" "app_db" {
  provider = ccp
  count    = var.enable_database ? 1 : 0

  name           = "${var.org_prefix}-${lower(var.region)}-pg"
  region         = var.region
  vpc_id         = module.vpc.vpc_id
  vnet_id        = module.vpc.vnet_ids.data
  plan           = var.db_plan
  replicas       = var.db_replicas
  engine_version = var.db_engine_version
  storage_gb     = var.db_storage_gb
  tags           = concat(["app:web", "role:db"], local.base_tags)
}
