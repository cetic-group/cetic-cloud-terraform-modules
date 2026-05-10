# managed/registry

Module Terraform pour une **CETIC Container Registry (CCR)** — registry privé OCI Docker/Helm hébergé dans votre tenant.

La registry est exposée via les **2 gateways régionales partagées** de la plateforme avec un **hostname unique split-horizon DNS** :
- Public : DNS IONOS → IP gateway publique
- Privé : DNS interne CETIC → IP gateway privée (LAN CETIC)

Vous activez l'un, l'autre, ou les deux modes via `expose_public` / `expose_private`.

## Exemple

```hcl
module "registry" {
  source  = "./modules/managed/registry"

  name           = "prod"
  region         = "RNN"
  expose_public  = true
  expose_private = true
  tags           = ["env:prod"]
}

output "docker_login_url" {
  value = module.registry.url
}

output "admin_password" {
  value     = module.registry.admin_password
  sensitive = true
}
```

## Inputs

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `name` | string | yes | — | Nom (1–100 chars). |
| `region` | string | yes | — | `RNN` / `PAR` / `ABJ`. Force replacement. |
| `expose_public` | bool | no | `false` | Expose sur Internet. |
| `expose_private` | bool | no | `true` | Expose sur le LAN CETIC. |
| `image_tag` | string | no | `null` | Tag image `registry`. `null` = défaut backoffice. |
| `tags` | list(string) | no | `[]` | Free-form tags (max 60, max 50 chars chacun). |

Au moins un de `expose_public` / `expose_private` doit être `true` (precondition).

## Outputs

| Name | Sensitive | Description |
|---|---|---|
| `id` | no | UUID de la registry. |
| `name` | no | Nom. |
| `slug` | no | Slug DNS. |
| `region` | no | Région. |
| `url` | no | URL HTTPS unique (split-horizon). |
| `expose_public` | no | Reachable Internet. |
| `expose_private` | no | Reachable LAN CETIC. |
| `status` | no | `creating` / `provisioning` / `active` / `error` / `deleting`. |
| `admin_username` | no | Admin user (typically `admin`). |
| `admin_password` | yes | One-shot password — écrit dans le state à la création. |
| `storage_used_gb` | no | Stockage utilisé (GB). |
| `last_push_at` | no | Dernier push observé. |

## Notes

- **`admin_password`** est retourné UNE SEULE FOIS à la création et stocké dans le state Terraform. Sécurisez votre backend state.
- Pour rotater le password admin, `terraform taint module.registry.ccp_registry.this` puis `terraform apply` — la registry sera recréée.
- Le `region` force le replacement (la registry vit dans le cluster workload de cette région).
- Pas de VPC/VNet/IP publique à provisionner — la plateforme gère ça via les gateways partagées.
