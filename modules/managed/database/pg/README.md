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

## Outputs

| Name | Description |
|------|-------------|
| `id` | UUID. |
| `tier` | `dev` ou `prod`. |
| `endpoint_host` / `endpoint_port` / `endpoint` | Connexion. |
| `admin_username` / `admin_database` | |
| `status` | |

## Notes

- **Password** : pas exposé par le provider (cf. backlog v0.8.0 — datasource `ccp_db_pg_credentials`). Récupérer via `cetic db pg credentials <id>` (CLI) ou `GET /v1/db/pg/{id}/credentials` (API) en attendant.
- `replicas` est immutable — pour passer dev → prod, recréer une instance et restore depuis snapshot.
- `engine_version` immutable — upgrades majeurs via dump/restore.
