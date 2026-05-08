# Module `compute/container`

Wrapper minimal autour de `ccp_container_instance` (LXC). Toutes les options classiques exposées (cloud-init `user_data`, SSH, IP publique, root password).

## Exemple

```hcl
module "web_01" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/compute/container?ref=v0.1.0"

  name        = "web-01"
  region      = "RNN"
  plan        = "small"
  template    = "ubuntu-24.04"
  vnet_id     = module.vpc.vnet_ids.web
  ssh_key_ids = [module.ssh_key.id]
  user_data   = file("./cloud-init.yaml")
  tags        = ["web", "env:prod"]
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | string | yes | — | Nom (1-80 chars). |
| `region` | string | yes | — | `RNN` / `PAR` / `ABJ`. |
| `plan` | string | no | `"small"` | `nano` … `xlarge`. |
| `template` | string | no | `"ubuntu-24.04"` | Template OS ou UUID custom. |
| `vnet_id` | string | yes | — | UUID du VNet. |
| `ssh_key_ids` | list(string) | no | `[]` | UUIDs de clés SSH. |
| `user_data` | string | no | `null` | Cloud-init. |
| `public_ip_id` | string | no | `null` | IP publique à attacher. |
| `root_password` | string | no | `null` | Sensible. |
| `tags` | list(string) | no | `[]` | |

## Outputs

| Name | Description |
|------|-------------|
| `id` | UUID. |
| `ip_address` | IP privée. |
| `public_ip_address` | IP publique. |
| `status` | |
| `cores` / `memory_mb` / `disk_gb` | Capacités effectives. |
