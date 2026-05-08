# Module `managed/database/ferretdb`

Wrapper minimal autour de `ccp_db_ferretdb_instance` (FerretDB v2 (Mongo-compat) managé).

## Exemple

```hcl
module "app_ferretdb" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/managed/database/ferretdb?ref=v0.1.0"

  name           = "app-ferretdb"
  region         = "RNN"
  vpc_id         = module.vpc.vpc_id
  vnet_id        = module.vpc.vnet_ids.data
  plan           = "medium"
  storage_gb     = 50
  replicas       = 3       # tier "prod"
  engine_version = "2.7"
}
```

Inputs / Outputs : identiques à `managed/database/pg` (mêmes options).
Default port et engine_version diffèrent selon le moteur.

Voir `managed/database/pg/README.md` pour la liste détaillée + notes
(password non exposé, replicas immutable, etc.).
