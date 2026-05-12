module "vpc_prod" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/vpc?ref=v0.3.4"

  for_each = var.vpc_map

  name   = each.key
  region = each.value.region
  vnets  = each.value.vnets
}


