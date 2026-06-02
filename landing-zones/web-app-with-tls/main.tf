locals {
  base_tags = concat(
    [
      "landing-zone:web-app-with-tls",
      "org:${var.org_prefix}",
      "region:${var.region}",
    ],
    var.tags_extra,
  )

  vpc_name       = "${var.org_prefix}-${lower(var.region)}-vpc"
  app_name       = "${var.org_prefix}-${lower(var.region)}-app"
  appgw_name     = "${var.org_prefix}-${lower(var.region)}-appgw"
  effective_host = var.hostname
}

# ── Identité ────────────────────────────────────────────────────────────────
module "ssh_key" {
  source = "../../modules/atomic/ssh-key"

  name       = "${var.org_prefix}-${lower(var.region)}-ops"
  public_key = var.ssh_public_key
}

# ── Réseau ──────────────────────────────────────────────────────────────────
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
      # L'AppGW expose elle-même 80/443 via la public IP — les containers backend
      # n'ont pas besoin de firewall entrant côté Internet (ils sont uniquement
      # accédés depuis la gateway, dans le même VNet).
      firewall_rules = []
    }
  }
}

# ── IP publique (attachée à l'AppGW) ────────────────────────────────────────
module "public_ip" {
  source = "../../modules/network/public-ip"

  region = var.region
}

# ── Container backend (single instance — la landing-zone vise un cas simple) ─
resource "ccp_container_instance" "app" {
  provider      = ccp
  name          = local.app_name
  region        = var.region
  plan          = var.app_plan
  template      = var.app_template
  vnet_id       = module.vpc.vnet_ids.web
  ssh_key_ids   = [module.ssh_key.id]
  root_password = var.app_root_password
  tags          = concat(["app:web"], local.base_tags)
}

# ── Application Gateway : 1 listener custom-domain + 1 TG + 1 route ──────────
module "appgw" {
  source = "../../modules/managed/application-gateway"

  name         = local.appgw_name
  region       = var.region
  plan         = var.appgw_plan
  vpc_id       = module.vpc.vpc_id
  vnet_id      = module.vpc.vnet_ids.web
  public_ip_id = module.public_ip.id
  tags         = local.base_tags

  hostnames      = [local.effective_host]
  acme_challenge = "http01" # cert Let's Encrypt — un CNAME vers la gateway doit être en place avant apply

  force_https  = true
  hsts_enabled = true

  target_groups = {
    default = {
      algorithm = "roundrobin"
      health_check = {
        protocol      = "http"
        path          = var.app_health_path
        expect_status = 200
        interval_sec  = 5
      }
      members = {
        m1 = {
          container_id = ccp_container_instance.app.id
          port         = var.app_listen_port
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
      policies = {
        waf_preset       = var.waf_preset
        basic_auth_users = var.basic_auth_users
      }
    },
  ]
}
