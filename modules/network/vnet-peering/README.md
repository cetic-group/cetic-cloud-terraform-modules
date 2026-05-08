# Module `network/vnet-peering`

Wrapper minimal autour de `ccp_vnet_peering`. Peer 2 VNets entre eux —
intra-VPC ou inter-VPC, peu importe. Le backend accepte n'importe quel
couple de VNets du même tenant.

> CETIC Cloud n'expose **pas** de "peering au niveau VPC" qui fédèrerait
> tous les VNets de 2 VPCs en une seule ressource. Pour peer plusieurs
> couples, déclarer une instance de ce module par couple.

## Exemple

```hcl
module "data_to_web_cross_vpc" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/vnet-peering?ref=v0.3.0"

  name      = "prod-data-to-staging-web"
  vnet_a_id = module.vpc_prod.vnet_ids.data
  vnet_b_id = module.vpc_staging.vnet_ids.web
  tags      = ["env:prod", "purpose:cross-tier"]
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `name` | string | yes | Nom du peering (2-100 chars). |
| `vnet_a_id` | string | yes | UUID d'un VNet (ordre indifférent). |
| `vnet_b_id` | string | yes | UUID de l'autre VNet. |
| `tags` | list(string) | no | Tags. |

## Outputs

| Name | Description |
|------|-------------|
| `id` | UUID. |
| `status` | `pending` / `active` / `deleting` / `error`. |
