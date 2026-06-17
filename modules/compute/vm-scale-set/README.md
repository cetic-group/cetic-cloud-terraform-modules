# Module `compute/vm-scale-set`

Wrapper minimal autour de `ccp_vm_scale_set`. Réplicas VM QEMU auto-managés.

```hcl
module "kafka_brokers" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/compute/vm-scale-set?ref=v0.1.0"

  name              = "kafka-brokers"
  region            = "RNN"
  plan              = "large"
  template          = "ubuntu-24.04"
  vnet_id           = module.vpc.vnet_ids.data
  min_instances     = 3
  max_instances     = 7
  desired_instances = 3
  tags              = ["kafka"]
}
```

## Scale set Windows

Template Windows (`win-*`) ou template custom Windows. Membres accédés en **RDP**
(compte `Administrator`). `windows_license_consent = true` obligatoire (CETIC
Cloud ne fournit pas les licences). Plan `medium`+ et mot de passe administrateur
fort (≥ 12 caractères, ≥ 3 catégories). L'ajout/retrait d'un VNet (primaire ou
secondaire) est appliqué **à chaud** sans recréer les membres.

```hcl
module "win_pool" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/compute/vm-scale-set?ref=v0.30.0"

  name              = "win-pool"
  region            = "RNN"
  plan              = "medium"
  template          = "win-2022"
  vnet_id           = module.vpc.vnet_ids.main
  desired_instances = 2
  min_instances     = 1
  max_instances     = 4
  root_password     = var.windows_admin_password

  windows_license_consent = true
}
```

Inputs / Outputs : identiques à `compute/container-scale-set`, plus `windows_license_consent` (input) et `os_family` (output).
