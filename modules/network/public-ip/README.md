# Module `network/public-ip`

Wrapper autour de `ccp_public_ip` — alloue une ou plusieurs IPs publiques dans une région. L'attach sur un container/VM/LB se fait depuis ces ressources via leur champ `public_ip_id`.

## Exemple — une IP nommée

```hcl
module "lb_ip" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/public-ip?ref=v0.23.0"

  region      = "RNN"
  label       = "passerelle-prod"
  description = "IP fixe du frontal web de production"
}

resource "ccp_load_balancer" "web" {
  # ...
  public_ip_id = module.lb_ip.id
}
```

## Exemple — plusieurs IPs (label suffixé `-1`, `-2`, …)

```hcl
module "api_ips" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/public-ip?ref=v0.23.0"

  region   = "RNN"
  quantity = 3
  label    = "ip-fixe-api" # → ip-fixe-api-1, ip-fixe-api-2, ip-fixe-api-3
}

output "api_ip_addresses" {
  value = module.api_ips.ip_addresses # liste de 3 adresses
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `region` | string | yes | — | `RNN`, `PAR`, `ABJ`. |
| `pool_id` | string | no | `null` | UUID du pool source — `null` = 1er pool dispo. |
| `quantity` | number | no | `1` | Nombre d'IPs à allouer (1-8). Si > 1, le `label` est suffixé `-1`, `-2`, … |
| `label` | string | no | `null` | Nom optionnel de l'IP (max 100 chars). |
| `description` | string | no | `null` | Description optionnelle. |

## Outputs

| Name | Description |
|------|-------------|
| `id` | UUID de la 1re IP (rétro-compat). |
| `ip_address` | IP allouée (1re IP). |
| `status` | `available` / `allocated` / `attached` / `reserved` (1re IP). |
| `attached_to_id` | UUID de la ressource attachée (1re IP). |
| `attached_to_type` | `container` / `vm_instance` (1re IP). |
| `label` | Label de la 1re IP. |
| `description` | Description de la 1re IP. |
| `ids` | Liste des UUID de toutes les IPs. |
| `ip_addresses` | Liste de toutes les adresses IP. |
| `labels` | Liste de tous les labels (suffixés si `quantity > 1`). |

## Notes

- Les outputs singuliers (`id`, `ip_address`, …) pointent toujours sur la **1re** IP allouée — rétro-compatibles avec l'usage `quantity = 1`.
- Pour adresser une IP spécifique quand `quantity > 1`, utiliser les outputs liste (`ids[1]`, `ip_addresses[2]`, …).
