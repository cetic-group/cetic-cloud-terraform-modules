# Exemple — Planificateur marche/arrêt (nuits + week-ends)

Exemple bout-en-bout du module [`atomic/schedule`](../../modules/atomic/schedule)
qui éteint des ressources hors heures ouvrées pour couper la facture des
charges non-prod.

Il provisionne un VPC puis trois cibles pilotées par un `ccp_schedule`
chacune :

| Cible | `resource_type` | Fenêtres OFF |
|-------|-----------------|--------------|
| Une VM | `vm` | Nuits de semaine 20:00→08:00 **et** week-end (ven 20:00 → lun 08:00) |
| Un VM scale set | `vm_scale_set` | Idem — mêmes `office_hours_windows` |
| Un pool de nodes CCKS (`ci`) | `ccks_node_pool` | Week-end uniquement (ven 20:00 → lun 08:00) |

Le pool CCKS est ciblé par son **id de pool** (`module.k8s.additional_pool_ids["ci"]`),
pas par l'id du cluster : le plan de contrôle et les autres pools restent
allumés.

> **Éteindre n'est pas détruire.** Les ressources « scheduled-off » sont
> arrêtées, pas supprimées. Supprimer un planning rallume sa cible.

## Utilisation

```bash
export TF_VAR_ccp_api_key="ccp_xxx"
export TF_VAR_root_password="ChangeMe-Str0ng!"

terraform init
terraform plan
terraform apply
```

## Points clés de syntaxe

- `windows` est un **`ListNestedAttribute`** du provider : on écrit
  `windows = [ { start_day = ..., ... }, ... ]` (liste d'objets), **jamais**
  des blocs `windows { ... }`.
- Jours : `0`=Lundi … `6`=Dimanche. Heures : entiers `0..24` (`HH:00`).
- Une fenêtre dont la fin est plus tôt dans la semaine que le début
  (ex. vendredi → lundi) **enjambe le week-end** automatiquement.
- La plateforme rejette (422) les fenêtres < 1h, les écarts < 1h, les
  chevauchements ou plus de deux cycles par jour (anti-flapping) : le
  message est remonté verbatim dans l'erreur de plan.
