# Accès VPN privé — un VPC privé joignable à distance via une passerelle VPN.
# Deux clients enregistrés : un avec sa propre clé publique (recommandé), un
# avec une configuration générée par la plateforme.

terraform {
  required_version = ">= 1.7"
  required_providers {
    ccp = {
      source  = "cetic-group/ccp"
      version = ">= 5.0.0"
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

variable "alice_public_key" {
  type        = string
  description = "Clé publique du poste d'Alice (générée côté client, jamais partagée en privé)."
}

module "vpc" {
  source = "../../modules/network/vpc"

  name   = "private-net"
  region = "RNN"

  vnets = {
    main = {
      cidr = "10.10.0.0/24"
      snat = true
    }
  }
}

module "vpn" {
  source = "../../modules/managed/vpn-gateway"

  name           = "ops"
  region         = "RNN"
  plan           = "small"
  vpc_id         = module.vpc.vpc_id
  peer_pool_cidr = "10.99.0.0/24"
  dns            = ["10.10.0.2"]
  tags           = ["env:prod", "team:ops"]

  peers = {
    # Modèle recommandé : Alice fournit sa clé publique, aucune clé privée ne
    # transite par la plateforme ni par le state.
    alice = {
      public_key = var.alice_public_key
    }
    # Modèle « clé générée » : la plateforme retourne une config prête à l'emploi
    # (récupérée une seule fois, ici stockée dans le state).
    laptop-ci = {
      managed           = true
      store_private_key = true
    }
  }

  # Ordre de destruction : la passerelle est détruite avant le VPC.
  depends_on = [module.vpc]
}

output "vpn_endpoint" {
  description = "Point d'entrée VPN à utiliser côté client."
  value       = "${module.vpn.endpoint_host}:${module.vpn.endpoint_port}"
}

output "vpn_gateway_public_key" {
  description = "Clé publique de la passerelle (à renseigner dans la config client)."
  value       = module.vpn.public_key
}

output "vpn_peer_addresses" {
  description = "Adresse privée assignée à chaque client."
  value       = { for k, p in module.vpn.peers : k => p.ip }
}

output "vpn_peer_configs" {
  description = "Configurations clientes générées par la plateforme (sensible)."
  value       = module.vpn.peer_configs
  sensitive   = true
}
