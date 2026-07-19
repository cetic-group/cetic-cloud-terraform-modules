# Module `atomic/schedule`

Wrapper minimal 1-1 autour de `ccp_schedule` — le **planificateur
marche/arrêt** de CETIC Cloud. Éteint une ressource cible (VM, container,
scale set, pool de nodes CCKS ou instance de base de données managée)
pendant des **fenêtres OFF hebdomadaires** déclarées, et la rallume en
dehors. Le moyen classique de réduire la facture des charges non-prod en
les coupant la nuit et le week-end.

La cible est adressée de façon polymorphe par `resource_type` +
`resource_id` : un seul type de module pilote VM, containers, scale sets,
pools de nodes ou bases managées.

> **Éteindre n'est pas détruire.** Une ressource « scheduled-off » est
> arrêtée, jamais supprimée. Pour un `db_instance`, les données stockées
> sont conservées (seul le compute est ramené à zéro). Supprimer le
> planning rallume la cible.

## Exemple — Éteindre une VM nuits + week-ends

```hcl
module "vm_office_hours" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/schedule?ref=v0.32.0"

  name          = "webapp-office-hours"
  resource_type = "vm"
  resource_id   = module.app_vm.id
  timezone      = "Europe/Paris"

  windows = [
    # Week-end : OFF du vendredi 20:00 au lundi 08:00
    { start_day = 4, start_hour = 20, end_day = 0, end_hour = 8 },
    # Nuits de semaine : OFF 20:00 → 08:00
    { start_day = 0, start_hour = 20, end_day = 1, end_hour = 8 },
    { start_day = 1, start_hour = 20, end_day = 2, end_hour = 8 },
    { start_day = 2, start_hour = 20, end_day = 3, end_hour = 8 },
    { start_day = 3, start_hour = 20, end_day = 4, end_hour = 8 },
  ]
}
```

## Exemple — Éteindre un pool de nodes CCKS le week-end

`resource_type = "ccks_node_pool"` cible **un seul pool de nodes** — le
plan de contrôle et les autres pools ne sont pas touchés.

```hcl
module "ci_pool_weekend" {
  source = "../../modules/atomic/schedule"

  name          = "ci-pool-weekend-off"
  resource_type = "ccks_node_pool"
  resource_id   = module.k8s.additional_pool_ids["ci"]

  windows = [
    { start_day = 4, start_hour = 20, end_day = 0, end_hour = 8 }, # ven 20:00 → lun 08:00
  ]
}
```

## Exemple — Définir un planning sans l'appliquer

`enabled = false` conserve le planning défini mais en pause — la cible
reste dans l'état d'alimentation courant.

```hcl
module "staging_db_paused" {
  source = "../../modules/atomic/schedule"

  name          = "staging-db-nights"
  resource_type = "db_instance"
  resource_id   = module.staging_pg.id
  enabled       = false

  windows = [
    { start_day = 0, start_hour = 22, end_day = 1, end_hour = 7 },
  ]
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | string | yes | — | Label lisible, unique dans l'org (1-63 chars). Mutable in-place. |
| `resource_type` | string | yes | — | `vm`, `container`, `vm_scale_set`, `container_scale_set`, `ccks_node_pool` ou `db_instance`. **Immuable** (force replace). |
| `resource_id` | string | yes | — | UUID de la cible. Pour `ccks_node_pool` : id du pool, pas du cluster. **Immuable** (force replace). |
| `windows` | list(object) | yes | — | ≥ 1 fenêtre OFF `{ start_day, start_hour, end_day, end_hour }`. Jours 0..6 (Lun..Dim), heures 0..24. Mutable. |
| `timezone` | string | no | `Europe/Paris` | Timezone IANA d'interprétation des fenêtres. Mutable. |
| `enabled` | bool | no | `true` | Si `false`, planning conservé mais jamais appliqué. Mutable. |

## Outputs

| Name | Description |
|------|-------------|
| `id` | UUID du planning. |
| `current_state` | Dernier état appliqué : `on` ou `off`. |
| `last_transition_at` | RFC 3339 de la dernière transition, ou null. |
| `estimated_monthly_fee_cents` | Frais mensuels estimés du scheduler (centimes). |

## Notes

- **`resource_type` et `resource_id` sont immuables.** Re-pointer un
  planning vers une autre cible force un destroy + create.
- **`name`, `timezone`, `enabled` et `windows` sont mutables in-place**
  (PATCH).
- **Anti-flapping.** La facturation est horaire : la plateforme rejette
  (422) les fenêtres < 1h, les écarts entre fenêtres < 1h, les fenêtres
  qui se chevauchent, ou plus de deux cycles marche/arrêt par jour. Le
  message d'erreur de l'API est remonté verbatim dans l'erreur de plan.
- **Syntaxe `windows`.** C'est un `ListNestedAttribute` du provider :
  utiliser la forme liste d'objets `windows = [ { ... }, { ... } ]`, PAS
  des blocs `windows { ... }`.
- **Fenêtre qui enjambe le week-end.** Quand `end` est plus tôt dans la
  semaine que `start` (ex. vendredi → lundi), l'intervalle wrappe
  automatiquement.
