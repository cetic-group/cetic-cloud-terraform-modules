# Module `compute/container-scale-set`

Wrapper minimal autour de `ccp_container_scale_set`. Réplicas auto-managés (`min`/`max`/`desired`), avec auto-repair des instances tombées.

> ⚠️ Le provider expose actuellement le scale set sans `ssh_key_ids`. Pour SSH, utiliser un cloud-init dans le template ou un custom template avec clés pré-injectées (cf. `atomic/custom-template`).
> ⚠️ Le LB ne peut pas attacher un scale set comme backend en TF natif (le provider expose `container_id` / `vm_instance_id` mais pas `scale_set_id`). Pour ce pattern, utiliser N containers individuels.

## Exemple

```hcl
module "api_workers" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/compute/container-scale-set?ref=v0.1.0"

  name              = "api-workers"
  region            = "RNN"
  plan              = "small"
  vnet_id           = module.vpc.vnet_ids.web
  min_instances     = 2
  max_instances     = 10
  desired_instances = 3
  disk_gb           = 60 # défaut du plan `small` dépassé, appliqué à chaque réplica
  tags              = ["api", "env:prod"]
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `disk_gb` | number | `null` | Taille du disque racine en GB, appliquée à chaque réplica. `null` = défaut du plan. Grow-only. |
| `docker` | bool | `false` | Activer Docker (nesting) sur chaque réplica. Désactivé = réplicas durcis contre la fuite de topologie de l'hôte. Forces new resource. |

(Autres inputs : cf. `compute/container`, mêmes options hors `ssh_key_ids`/`public_ip_id`, plus `min_instances`/`max_instances`/`desired_instances`/`auto_repair`.)
