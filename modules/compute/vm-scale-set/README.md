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

Inputs / Outputs : identiques à `compute/container-scale-set`.
