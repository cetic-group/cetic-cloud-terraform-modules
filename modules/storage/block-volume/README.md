# Module `storage/block-volume`

Wrapper minimal autour de `ccp_block_volume` (Ceph RBD). L'attachement est exposé via un object `attach_to = { id, type }` qui simplifie l'usage par rapport aux 2 args séparés du provider.

## Exemple

```hcl
module "data_disk" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/storage/block-volume?ref=v0.1.0"

  name    = "data-disk-01"
  region  = "RNN"
  size_gb = 100

  attach_to = {
    id   = ccp_container_instance.web.id
    type = "container"
  }

  tags = ["env:prod"]
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `name` | string | yes | 1-100 chars. |
| `region` | string | yes | `RNN`/`PAR`/`ABJ`. |
| `size_gb` | number | yes | 1-16384. Mutable up only. |
| `attach_to` | object({id, type}) | no | `type` ∈ `container` / `vm` (`vm_instance` accepté comme alias legacy déprécié, mappé sur `vm`). |
| `tags` | list(string) | no | |

## Outputs

| Name | Description |
|------|-------------|
| `id` / `status` / `size_gb` / `attached_to_id` | |
