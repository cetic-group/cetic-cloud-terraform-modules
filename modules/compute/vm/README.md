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

## VM Windows

Utilisez un template Windows (`win-*`) ou un template custom capturé depuis une
VM Windows. Accès en **RDP** (pas de SSH) ; compte `Administrator`. CETIC Cloud
ne fournit pas les licences Windows → `windows_license_consent = true` obligatoire.
Plan `medium`+ requis et mot de passe administrateur fort (≥ 12 caractères, ≥ 3
catégories).

```hcl
module "win_vm" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/compute/vm?ref=v0.30.0"

  name          = "win-app"
  region        = "RNN"
  plan          = "medium"
  template      = "win-2022"
  vnet_id       = module.vpc.vnet_ids.main
  root_password = var.windows_admin_password # compte Administrator

  windows_license_consent = true
}
```

L'output `os_family` vaut `windows` pour une VM Windows, `linux` sinon.

Inputs / Outputs : identiques à `compute/container` (mêmes options, ressource différente), plus `windows_license_consent` (input) et `os_family` (output).
