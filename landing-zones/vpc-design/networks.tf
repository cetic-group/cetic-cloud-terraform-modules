module "vpc_prod" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/vpc?ref=v0.3.4"

  for_each = var.vpc_map

  name   = each.key
  region = each.value.region
  vnets  = each.value.vnets
}

module "vpc-prod_10_0_to_vpc-prod_10_1" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/vnet-peering?ref=v0.3.4"

  name      = "prod-data-to-staging-web"
  vnet_a_id = module.vpc_prod["vpc-prod-10-0"].vnet_ids["vnet-10-0-1"]
  vnet_b_id = module.vpc_prod["vpc-prod-10-1"].vnet_ids["vnet-10-1-1"]
  tags      = ["prod"]
}

