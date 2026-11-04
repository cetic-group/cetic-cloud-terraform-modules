# Module `managed/database/pg`

Wrapper minimal autour de `ccp_db_pg_instance` (PostgreSQL managé, multi-replica).

## Exemple

```hcl
module "app_db" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/managed/database/pg?ref=v0.1.0"

  name           = "app-postgres"
  region         = "RNN"
  vpc_id         = module.vpc.vpc_id
  vnet_id        = module.vpc.vnet_ids.data
  plan           = "medium"
  storage_gb     = 100
  replicas       = 3       # tier "prod"
  engine_version = "16"
  tags           = ["env:prod"]

  # Extensions (région qui les propose ; instance plus ancienne : activation à demander)
  allowed_extensions = ["pg_cron", "pg_stat_statements"]
  preload_libraries  = ["pg_cron", "pg_stat_statements"]
  cron_database      = "app"
}

output "db_endpoint" {
  value = module.app_db.endpoint
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | string | yes | — | Nom. |
| `region` | string | yes | — | `RNN`/`PAR`/`ABJ`. |
| `vpc_id` | string | yes | — | VPC. |
| `vnet_id` | string | yes | — | VNet (privé recommandé). |
| `plan` | string | no | `"small"` | `nano` … `xlarge`. |
| `storage_gb` | number | no | `20` | 1-1000. |
| `replicas` | number | no | `1` | `1` (dev) ou `3` (prod). Le `tier` est dérivé. |
| `engine_version` | string | no | `"16"` | Version majeure PG. |
| `tags` | list(string) | no | `[]` | |
| `allowed_extensions` | set(string) | no | `null` | Extensions du catalogue autorisées (`CREATE EXTENSION`). `null` : inchangé ; `[]` : aucune. |
| `preload_libraries` | set(string) | no | `null` | Bibliothèques chargées au démarrage (`pg_cron`, `pg_stat_statements`). Un changement redémarre l'instance. `null` : inchangé ; `[]` : aucune. |
| `cron_database` | string | no | `null` | Base des tâches `pg_cron` (exige `pg_cron` dans `preload_libraries`). `null` : inchangé. |

## Outputs

| Name | Description |
|------|-------------|
| `id` | UUID. |
| `tier` | `dev` ou `prod`. |
| `endpoint_host` / `endpoint_port` / `endpoint` | Connexion. |
| `admin_username` / `admin_database` | |
| `status` | |
| `extensions_available` | `true` si des extensions peuvent être autorisées sur l'instance. |
| `extensions_status` | `applied` ou `pending` (changement en cours d'application). |

## Notes

- **Extensions** : `allowed_extensions`, `preload_libraries` et `cron_database` se modifient en place (pas de recréation) ; `terraform apply` attend `extensions_status = "applied"`. Elles exigent le provider `cetic-group/ccp >= 7.3.0` et que les extensions soient activées sur l'instance (`extensions_available = true`). Par défaut (`null`) le module ne touche pas aux réglages existants.
- **Password** : pas exposé par le provider (cf. backlog v0.8.0 — datasource `ccp_db_pg_credentials`). Récupérer via `cetic db pg credentials <id>` (CLI) ou `GET /v1/db/pg/{id}/credentials` (API) en attendant.
- `replicas` est immutable — pour passer dev → prod, recréer une instance et restore depuis snapshot.
- `engine_version` immutable — upgrades majeurs via dump/restore.
