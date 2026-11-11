# Exemple — images ou site statique servis depuis un bucket public
# sous votre propre domaine, via une passerelle applicative.
#
# Après `terraform apply`, créez UN enregistrement DNS chez votre
# hébergeur pour `www.example.com` (CNAME ou A vers la passerelle, selon
# ce que la console / `cetic appgw listener dns-check` indique).

terraform {
  required_providers {
    ccp = {
      source  = "cetic-group/ccp"
      version = ">= 7.3.2" # utiliser la version du provider qui porte `kind` sur ccp_appgw_target_group
    }
  }
}

variable "ccp_api_key" {
  type      = string
  sensitive = true
}

provider "ccp" {
  api_key = var.ccp_api_key
}

module "vpc" {
  source = "../../modules/network/vpc"

  name   = "static-site"
  region = "RNN"
  vnets = {
    web = { cidr = "10.0.1.0/24", snat = true }
  }
}

module "public_ip" {
  source = "../../modules/network/public-ip"

  region = "RNN"
}

# Le bucket doit être PUBLIC : un bucket privé est refusé.
module "assets" {
  source = "../../modules/storage/bucket"

  name      = "static-site-assets"
  region    = "RNN"
  is_public = true
}

module "web" {
  source = "../../modules/exposure/web-app-with-appgw"

  name         = "static-site"
  region       = "RNN"
  vpc_id       = module.vpc.vpc_id
  vnet_id      = module.vpc.vnet_ids.web
  public_ip_id = module.public_ip.id

  hostnames = ["www.example.com"]

  cache_enabled = true

  target_groups = {
    assets = {
      kind          = "bucket"
      bucket_id     = module.assets.id
      bucket_prefix = "site"
    }
  }

  routes = [
    {
      listener_index   = 0
      target_group_key = "assets"

      # Contenu stable (images, fichiers) : cache fort.
      cache_mode          = "force"
      cache_default_ttl_s = 3600
      cache_max_ttl_s     = 3600
    },
  ]
}

output "url" {
  value = module.web.url
}

output "origin_status" {
  value = module.web.target_group_origin_status
}
