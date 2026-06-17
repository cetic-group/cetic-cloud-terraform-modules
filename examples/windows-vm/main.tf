# Windows — une VM Windows + un VM scale set Windows, accédés en RDP.
#
# CETIC Cloud ne fournit PAS les licences Windows : vous devez détenir une
# licence valide par instance et l'attester via `windows_license_consent = true`.
# Une instance Windows exige un plan `medium`+ et un mot de passe administrateur
# fort (≥ 12 caractères, ≥ 3 catégories : minuscule / majuscule / chiffre / symbole).

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

variable "windows_admin_password" {
  type        = string
  sensitive   = true
  description = "Mot de passe administrateur Windows (≥ 12 caractères, ≥ 3 catégories). Passer via TF_VAR_windows_admin_password."
}

module "vpc" {
  source = "../../modules/network/vpc"

  name   = "win-demo"
  region = "RNN"

  vnets = {
    main = {
      cidr = "10.20.0.0/24"
      snat = true
    }
  }
}

# VM Windows unique
module "win_vm" {
  source = "../../modules/compute/vm"

  name          = "win-app"
  region        = "RNN"
  plan          = "medium" # Windows exige medium ou plus
  template      = "win-2022"
  vnet_id       = module.vpc.vnet_ids.main
  root_password = var.windows_admin_password # compte Administrator

  windows_license_consent = true

  tags       = ["windows", "rdp"]
  depends_on = [module.vpc]
}

# Scale set de VMs Windows
module "win_pool" {
  source = "../../modules/compute/vm-scale-set"

  name              = "win-pool"
  region            = "RNN"
  plan              = "medium"
  template          = "win-2022"
  vnet_id           = module.vpc.vnet_ids.main
  desired_instances = 2
  min_instances     = 1
  max_instances     = 4
  root_password     = var.windows_admin_password

  windows_license_consent = true

  tags       = ["windows", "rdp"]
  depends_on = [module.vpc]
}

output "vm_os_family" {
  value = module.win_vm.os_family
}

output "vm_ip" {
  value = module.win_vm.ip_address
}

output "pool_os_family" {
  value = module.win_pool.os_family
}
