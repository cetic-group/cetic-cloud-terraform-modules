# Module `atomic/appgw-target-group-member`

Wrapper 1-1 autour de `ccp_appgw_target_group_member`. Ajoute **un seul backend** dans un target group d'AppGW.

> 💡 Pour un usage courant, le module `atomic/appgw-target-group` gère déjà les members via une map en interne (`for_each` sur `var.members`). Ce module isolé est utile quand on a besoin de **résoudre dynamiquement** les members en dehors du HCL (data source, output d'un autre module, génération conditionnelle complexe) — ou pour piloter `enabled=false` (drain) sur un member précis sans toucher au reste du target group.

> **🇬🇧** 1-1 wrapper around `ccp_appgw_target_group_member`. Adds one single backend to an existing target group. Useful when you need dynamic member resolution outside HCL, or surgical control over `enabled` (drain) without touching the rest of the pool.

## Exemple — drain progressif d'un member

```hcl
module "tg" {
  source = "../appgw-target-group"
  # … members initiaux …
}

# Drain manuel d'un member existant sans réécrire le target group
module "drain_legacy" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/appgw-target-group-member?ref=v0.8.0"

  appgw_id        = module.appgw.id
  target_group_id = module.tg.id

  target_ip = "10.0.1.42"
  port      = 8080
  enabled   = false   # drain — la gateway skip ce backend mais le keeps en config
}
```

## Exemple — ajout d'un backend découvert dynamiquement

```hcl
data "ccp_container_instance" "extra" {
  name = "extra-worker"
}

module "extra_member" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/appgw-target-group-member?ref=v0.8.0"

  appgw_id        = module.appgw.id
  target_group_id = module.tg.id
  container_id    = data.ccp_container_instance.extra.id
  port            = 8080
  weight          = 50   # demi-poids vs les permanents
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `appgw_id` | string | yes | — | UUID de l'AppGW parente. **Immutable**. |
| `target_group_id` | string | yes | — | UUID du target group parent. **Immutable**. |
| `container_id` | string | XOR | `null` | UUID container backend. **Immutable**. |
| `vm_instance_id` | string | XOR | `null` | UUID VM backend. **Immutable**. |
| `target_ip` | string | XOR | `null` | IP raw dans le VNet. **Immutable**. |
| `port` | number | yes | — | Port backend (1-65535). **Immutable**. |
| `weight` | number | no | `100` | 0-1000. Mutable. |
| `enabled` | bool | no | `true` | Drain si `false`. Mutable. |

Exactement un de `container_id` / `vm_instance_id` / `target_ip` doit être défini (enforce via `precondition`).

## Outputs

| Name | Description |
|------|-------------|
| `id` | UUID du member. |
| `appgw_id` | UUID de la gateway parente. |
| `target_group_id` | UUID du target group parent. |
| `port` | Port effectif. |
| `weight` | Pondération effective. |
| `enabled` | État administratif. |

## Notes

- **Immuabilité** : `appgw_id`, `target_group_id`, le target (container/vm/ip) et `port` sont immutables. Pour changer un de ces champs, le member est détruit et recréé.
- **`enabled=false`** = drain : le backend reste enregistré (et donc visible dans `module.tg.members`) mais ne reçoit plus de trafic. Utile en deploy progressif avant retrait définitif.
- **Préférer `atomic/appgw-target-group` quand la liste des members est statique** — il les gère via `for_each` et garantit la cohérence du pool entier en un seul `terraform apply`.
