module "vpc_prod" {
  source = "../../modules/network/vpc"

  for_each = var.vpc_map

  name   = each.key
  region = each.value.region
  vnets  = each.value.vnets
}


