# billing-budget — module managed

> Composé : 1 `ccp_budget` (cap mensuel + alertes 50/80/100%) + optionnel
> `ccp_commit` (engagement -10% mensuel ou -20% annuel).

## Quick start

```hcl
module "budget" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/managed/billing-budget?ref=v0.23.2"

  monthly_budget_eur = 50          # plafond en euros (converti en cents)
  hard_stop_at_100   = true        # bloque création de ressources à 100%
  notify_emails      = ["finance@example.com"]
}
```

## Avec engagement -20% annuel

```hcl
module "budget_with_yearly_commit" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/managed/billing-budget?ref=v0.23.2"

  monthly_budget_eur = 200
  commit_type        = "yearly"    # -20% sur tous les usages
  commit_auto_renew  = true
}

output "yearly_saved_per_month" {
  value = module.budget_with_yearly_commit.commit_discount_pct
}
```

## Variables

| Nom | Type | Default | Description |
|---|---|---|---|
| `monthly_budget_eur` | number | (req) | Cap mensuel en euros (converti × 100 en cents) |
| `alert_thresholds_pct` | list(number) | `[50, 80, 100]` | Seuils alertes |
| `notify_emails` | list(string) | `[]` | Emails (vide = compte tenant) |
| `hard_stop_at_100` | bool | `false` | Bloquer création ressources à 100% |
| `commit_type` | string | `null` | `null` / `monthly` / `yearly` |
| `commit_auto_renew` | bool | `true` | Renouvellement auto |

## Outputs

| Nom | Description |
|---|---|
| `budget_id` | UUID du budget |
| `monthly_budget_cents` | Cap en cents |
| `last_alert_threshold_pct` | Dernière alerte déclenchée ce mois (ou null) |
| `commit_id` | UUID du commit (null si pas créé) |
| `commit_discount_pct` | % de remise active (null si pas de commit) |
| `commit_end_at` | Échéance du commit (RFC3339, null si pas de commit) |

## Compat

- Provider `ccp` `>= 0.16.0`
- CCP backend `v2.0.0+` (PR billing-v2)
