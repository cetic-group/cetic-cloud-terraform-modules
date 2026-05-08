# Module `network/public-ip`

Wrapper minimal autour de `ccp_public_ip` — alloue une IP publique dans une région. L'attach sur un container/VM/LB se fait depuis ces ressources via leur champ `public_ip_id`.

## Exemple

```hcl
module "lb_ip" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/public-ip?ref=v0.1.0"

  region = "RNN"
}

resource "ccp_load_balancer" "web" {
  # ...
  public_ip_id = module.lb_ip.id
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `region` | string | yes | — | `RNN`, `PAR`, `ABJ`. |
| `pool_id` | string | no | `null` | UUID du pool source — `null` = 1er pool dispo. |

## Outputs

| Name | Description |
|------|-------------|
| `id` | UUID. |
| `ip_address` | IP allouée. |
| `status` | `available` / `attached` / `attaching` / `detaching` / `error`. |
| `attached_to_id` | UUID de la ressource attachée. |
| `attached_to_type` | `container` / `vm_instance` / `load_balancer`. |
