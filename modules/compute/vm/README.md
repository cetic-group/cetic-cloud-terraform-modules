# Module `compute/vm`

Wrapper minimal autour de `ccp_vm_instance` (QEMU). Expose les options classiques (cloud-init, SSH keys, IP publique).

## Exemple

```hcl
module "db_vm" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/compute/vm?ref=v0.1.0"

  name        = "db-primary"
  region      = "RNN"
  plan        = "medium"
  template    = "ubuntu-24.04"
  vnet_id     = module.vpc.vnet_ids.data
  ssh_key_ids = [module.ssh_key.id]
  user_data   = file("./bootstrap-db.yaml")

  bastion_access = true # opt-in : accès SSH via le Bastion du tenant
}
```

Inputs / Outputs : identiques à `compute/container` (mêmes options, ressource différente).
