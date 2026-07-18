# Planificateur marche/arrêt — éteindre nuits + week-ends
# ------------------------------------------------------
# Démontre le module `atomic/schedule` sur trois types de cibles :
#   1. une VM               (resource_type = "vm")
#   2. un VM scale set      (resource_type = "vm_scale_set")
#   3. un pool de nodes CCKS (resource_type = "ccks_node_pool")
#
# Le même profil de fenêtres OFF est partagé : OFF toutes les nuits de
# semaine 20:00 → 08:00 et tout le week-end (vendredi 20:00 → lundi 08:00),
# en Europe/Paris. Les ressources sont donc allumées uniquement pendant les
# heures ouvrées — l'économie classique sur les charges non-prod.

terraform {
  required_version = ">= 1.7"
  required_providers {
    ccp = {
      source  = "cetic-group/ccp"
      version = ">= 6.0.0"
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
  description = "Mot de passe root des VM (8–128 caractères). Passer via TF_VAR_root_password."
}

# Profil « heures ouvrées » partagé : OFF nuits + week-ends (Europe/Paris).
locals {
  office_hours_windows = [
    # Week-end : OFF du vendredi 20:00 au lundi 08:00
    { start_day = 4, start_hour = 20, end_day = 0, end_hour = 8 },
    # Nuits de semaine : OFF 20:00 → 08:00
    { start_day = 0, start_hour = 20, end_day = 1, end_hour = 8 },
    { start_day = 1, start_hour = 20, end_day = 2, end_hour = 8 },
    { start_day = 2, start_hour = 20, end_day = 3, end_hour = 8 },
    { start_day = 3, start_hour = 20, end_day = 4, end_hour = 8 },
  ]
}

# ─── Réseau ───────────────────────────────────────────────────────────────────
module "vpc" {
  source = "../../modules/network/vpc"

  name   = "sched-demo"
  region = "RNN"

  vnets = {
    main = {
      cidr = "10.20.0.0/24"
      snat = true
    }
  }
}

# ─── 1. VM planifiée ──────────────────────────────────────────────────────────
module "app_vm" {
  source = "../../modules/compute/vm"

  name          = "sched-demo-vm"
  region        = "RNN"
  plan          = "small"
  template      = "ubuntu-24.04"
  vnet_id       = module.vpc.vnet_ids.main
  root_password = var.root_password
}

module "vm_schedule" {
  source = "../../modules/atomic/schedule"

  name          = "sched-demo-vm-office-hours"
  resource_type = "vm"
  resource_id   = module.app_vm.id
  timezone      = "Europe/Paris"
  windows       = local.office_hours_windows
}

# ─── 2. VM scale set planifié ─────────────────────────────────────────────────
module "app_vmss" {
  source = "../../modules/compute/vm-scale-set"

  name              = "sched-demo-vmss"
  region            = "RNN"
  plan              = "small"
  template          = "ubuntu-24.04"
  vnet_id           = module.vpc.vnet_ids.main
  min_instances     = 2
  max_instances     = 6
  desired_instances = 3
  root_password     = var.root_password
}

module "vmss_schedule" {
  source = "../../modules/atomic/schedule"

  name          = "sched-demo-vmss-office-hours"
  resource_type = "vm_scale_set"
  resource_id   = module.app_vmss.id
  timezone      = "Europe/Paris"
  windows       = local.office_hours_windows
}

# ─── 3. Pool de nodes CCKS planifié (juste le pool CI, week-end) ──────────────
module "k8s" {
  source = "../../modules/managed/k8s-cluster"

  name    = "sched-demo-cluster"
  region  = "RNN"
  vpc_id  = module.vpc.vpc_id
  vnet_id = module.vpc.vnet_ids.main

  additional_pools = {
    ci = {
      plan     = "medium"
      replicas = 2
    }
  }
}

module "ci_pool_schedule" {
  source = "../../modules/atomic/schedule"

  name          = "sched-demo-ci-pool-weekend"
  resource_type = "ccks_node_pool"
  resource_id   = module.k8s.additional_pool_ids["ci"]
  timezone      = "Europe/Paris"

  windows = [
    # Le pool CI ne tourne pas le week-end : OFF vendredi 20:00 → lundi 08:00
    { start_day = 4, start_hour = 20, end_day = 0, end_hour = 8 },
  ]
}

# ─── Sorties ──────────────────────────────────────────────────────────────────
output "vm_schedule_id" {
  value = module.vm_schedule.id
}

output "vmss_schedule_id" {
  value = module.vmss_schedule.id
}

output "ci_pool_schedule_id" {
  value = module.ci_pool_schedule.id
}

output "estimated_monthly_fee_cents" {
  description = "Somme des frais mensuels estimés du scheduler (centimes) sur les 3 plannings."
  value = (
    module.vm_schedule.estimated_monthly_fee_cents +
    module.vmss_schedule.estimated_monthly_fee_cents +
    module.ci_pool_schedule.estimated_monthly_fee_cents
  )
}
