# Quickstart — un container exposé via une IP publique attachée directement
# (pas de load balancer, pour la simplicité). 30 lignes pour démarrer.

terraform {
  required_version = ">= 1.7"
  required_providers {
    ccp = {
      source  = "cetic-group/ccp"
      version = ">= 4.3.0"
    }
  }
}

provider "ccp" {
  api_key = var.ccp_api_key
}

variable "ccp_api_key" {
  type      = string
  sensitive = true
}

variable "root_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe root (8–128 caractères). Passer via TF_VAR_root_password ou un secret backend."
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

resource "ccp_container_instance" "hello" {
  provider      = ccp
  name          = "hello-world"
  region        = "RNN"
  plan          = "nano"
  template      = "ubuntu-24.04"
  vnet_id       = module.vpc.vnet_ids.main
  ssh_key_ids   = [module.ssh_key.id]
  root_password = var.root_password
}

resource "ccp_public_ip" "this" {
  provider         = ccp
  region           = "RNN"
  attached_to_id   = ccp_container_instance.hello.id
  attached_to_type = "container"
}

output "ssh_command" {
  value = "ssh ubuntu@${ccp_public_ip.this.ip_address}"
}
