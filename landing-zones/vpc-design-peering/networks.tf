module "vpc_prod" {
  source = "../../modules/network/vpc"

  for_each = var.vpc_map

  name   = each.key
  region = each.value.region
  vnets  = each.value.vnets
}

module "vpc-prod_10_0_to_vpc-prod_10_1" {
  source = "../../modules/network/vnet-peering"

  name      = "prod-data-to-staging-web"
  vnet_a_id = module.vpc_prod["vpc-prod-10-0"].vnet_ids["vnet-10-0-1"]
  vnet_b_id = module.vpc_prod["vpc-prod-10-1"].vnet_ids["vnet-10-1-1"]
  tags      = ["prod"]
}

