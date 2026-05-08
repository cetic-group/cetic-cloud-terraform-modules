# Module `network/vpc-peering`

Wrapper minimal autour de `ccp_vpc_peering`. Établit un peering entre 2 VPCs (même région, CIDRs non-chevauchants). Le module `network/vpc` propose déjà l'argument `peering_accepter_vpc_ids` pour le cas standard ; ce module est utile quand on veut gérer les peerings séparément (lifecycle distinct, autre tenant pour cross-tenant).

## Exemple

```hcl
module "prod_to_staging" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/vpc-peering?ref=v0.1.0"

  requester_vpc_id = module.vpc_prod.vpc_id
  accepter_vpc_id  = module.vpc_staging.vpc_id
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `requester_vpc_id` | string | yes | UUID du VPC demandeur. |
| `accepter_vpc_id` | string | yes | UUID du VPC acceptant (même région). |

## Outputs

| Name | Description |
|------|-------------|
| `id` | UUID du peering. |
| `status` | Statut. |

## Notes

- Cross-tenant : le tenant accepter doit approuver l'invitation séparément (console / CLI). Intra-tenant = auto-accepté.
- Pas supporté cross-region.
