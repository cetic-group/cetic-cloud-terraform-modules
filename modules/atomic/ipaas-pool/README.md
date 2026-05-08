# Module `atomic/ipaas-pool` (admin only)

Wrapper minimal autour de `ccp_ipaas_pool` — déclare un pool BYOIP routé via un edge Scaleway. **L'API key utilisée doit avoir le scope `admin`**.

## Exemple

```hcl
module "ipaas_byoip_rnn" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/ipaas-pool?ref=v0.1.0"

  region    = "RNN"
  cidr      = "163.172.232.192/27"
  gateway   = "163.172.232.193"
  is_active = true
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `region` | string | yes | — | `RNN`, `PAR` ou `ABJ`. |
| `cidr` | string | yes | — | Bloc BYOIP. |
| `gateway` | string | yes | — | 1re IP utilisable. |
| `edge_id` | string | no | `null` | UUID de l'edge Scaleway. |
| `is_active` | bool | no | `true` | Active le pool. |

## Outputs

| Name | Description |
|------|-------------|
| `id` | UUID du pool. |
| `kind` | Toujours `ipaas_routed`. |
| `edge_id` | Edge associé. |
