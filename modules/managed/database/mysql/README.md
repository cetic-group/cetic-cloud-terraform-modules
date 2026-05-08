# Module `managed/database/mysql`

Wrapper minimal autour de `ccp_db_mysql_instance` (MariaDB (MySQL-compat) managé).

## Exemple

```hcl
module "app_mysql" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/managed/database/mysql?ref=v0.1.0"

  name           = "app-mysql"
  region         = "RNN"
  vpc_id         = module.vpc.vpc_id
  vnet_id        = module.vpc.vnet_ids.data
  plan           = "medium"
  storage_gb     = 50
  replicas       = 3       # tier "prod"
  engine_version = "11.4"
}
```

Inputs / Outputs : identiques à `managed/database/pg` (mêmes options).
Default port et engine_version diffèrent selon le moteur.

Voir `managed/database/pg/README.md` pour la liste détaillée + notes
(password non exposé, replicas immutable, etc.).
