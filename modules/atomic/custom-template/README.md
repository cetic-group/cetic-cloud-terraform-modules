# Module `atomic/custom-template`

Wrapper minimal autour de `ccp_custom_template` — capture un snapshot d'un container ou d'une VM en template réutilisable au sein de l'organisation.

## Exemple

```hcl
# Snapshot d'un container "golden image" en template
module "tpl_app_baseline" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/custom-template?ref=v0.1.0"

  name                = "app-baseline-2026-05-08"
  description         = "Stack Node 20 + nginx + monitoring agents"
  source_container_id = ccp_container_instance.golden.id
}

# Réutilisation dans une nouvelle instance
resource "ccp_container_instance" "app" {
  name        = "app-from-template"
  region      = "RNN"
  plan        = "small"
  template    = module.tpl_app_baseline.id  # UUID du custom template
  vnet_id     = module.vpc.vnet_ids.web
  ssh_key_ids = [module.ssh_key.id]
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `name` | string | yes | Nom (visible dans `/compute/templates`). |
| `description` | string | no | Description libre. |
| `source_container_id` | string | XOR | UUID du container source. |
| `source_vm_id` | string | XOR | UUID de la VM source. |

Exactement un de `source_container_id` / `source_vm_id` est requis.

## Outputs

| Name | Description |
|------|-------------|
| `id` | UUID du template. |
| `template_type` | `lxc` ou `vm`. |
| `region` | Région du template. |
| `disk_gb` | Taille du disque. |
