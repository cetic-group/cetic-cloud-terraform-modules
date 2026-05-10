# Quickstart — un container exposé via une IP publique attachée directement
# (pas de load balancer, pour la simplicité). 30 lignes pour démarrer.

terraform {
  required_version = ">= 1.7"
  required_providers {
    ccp = {
      source  = "cetic-group/cetic-cloud-platform"
      version = ">= 0.10.0"
    }
  }
}

provider "ccp" {
  endpoint = "https://api.cloud.cetic-group.com"
  api_key  = var.ccp_api_key
}

variable "ccp_api_key" {
  type      = string
  sensitive = true
}

module "ssh_key" {
  source = "../../modules/atomic/ssh-key"

  name       = "quickstart"
  public_key = file("~/.ssh/id_ed25519.pub")
}

module "vpc" {
  source = "../../modules/network/vpc"

  name   = "quickstart"
  region = "RNN"

  vnets = {
    main = {
      cidr = "10.10.0.0/24"
      snat = true
    }
  }
}

resource "ccp_public_ip" "this" {
  region = "RNN"
}

resource "ccp_container_instance" "hello" {
  name         = "hello-world"
  region       = "RNN"
  plan         = "nano"
  template     = "ubuntu-24.04"
  vnet_id      = module.vpc.vnet_ids.main
  ssh_key_ids  = [module.ssh_key.id]
  public_ip_id = ccp_public_ip.this.id
}

output "ssh_command" {
  value = "ssh ubuntu@${ccp_public_ip.this.ip_address}"
}
