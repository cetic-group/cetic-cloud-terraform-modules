# Module `network/vpc-peering`

Wrapper minimal autour de `ccp_vpc_peering`. Peer 2 VPCs entre eux —
établir une relation de peering inter-VPC pour permettre la communication
entre réseaux distincts.

## Exemple

```hcl
module "prod_to_staging_peering" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/vpc-peering?ref=v0.31.0"

  name     = "prod-to-staging"
  vpc_a_id = module.vpc_prod.id
  vpc_b_id = module.vpc_staging.id
  tags     = ["env:prod", "purpose:cross-vpc"]
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `name` | string | yes | Nom du peering inter-VPC (2-100 chars). |
| `vpc_a_id` | string | yes | UUID d'un VPC (ordre indifférent). |
| `vpc_b_id` | string | yes | UUID de l'autre VPC. |
| `tags` | list(string) | no | Tags (défaut `[]`). |

## Outputs

| Name | Description |
|------|-------------|
| `id` | UUID du peering. |
| `status` | `pending` / `active` / `deleting` / `error`. |
