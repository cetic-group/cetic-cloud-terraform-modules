# Module `managed/application-gateway`

Composable haut-niveau qui orchestre une **Application Gateway L7 complète** en un seul `module` block :

- 1 `application_gateway` (via `atomic/application-gateway`)
- N listeners (via `atomic/appgw-listener` — 1 par hostname)
- M target groups (via `atomic/appgw-target-group` — algorithm + health check + members in-place)
- K routes (via `atomic/appgw-route` — listener × path → target group, + policies + basic auth)

C'est le pendant **L7** de `managed/registry` ou `managed/database` : un service géré côté plateforme dont on déclare l'intent métier (hostnames, pools, règles) sans plomberie.

> **🇬🇧** High-level composable that bundles `application_gateway` + listeners + target groups + routes in one module call. The L7 counterpart of `managed/registry` and `managed/database`.

> 💡 Pour un cas plus simple (1 stack web 3-tier avec exposition AppGW automatique), voir la landing-zone `landing-zones/web-app-with-tls` ou l'option `exposure_type="appgw"` de `basic-web-app`.

## Exemple — API + admin avec routing path-based, HSTS, WAF et basic auth

```hcl
module "appgw_public_ip" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/public-ip?ref=v0.8.0"
  region = "RNN"
}

module "web" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/managed/application-gateway?ref=v0.8.0"

  name         = "acme-web"
  region       = "RNN"
  plan         = "medium"
  vpc_id       = module.vpc.vpc_id
  vnet_id      = module.vpc.vnet_ids.web
  public_ip_id = module.appgw_public_ip.id

  hostnames     = ["api.example.com", "admin.example.com"]
  custom_domain = true
  hsts_enabled  = true

  target_groups = {
    api = {
      algorithm = "leastconn"
      health_check = {
        path          = "/healthz"
        expect_status = 200
        interval_sec  = 10
      }
      members = {
        api_01 = { container_id = ccp_container_instance.api_01.id, port = 8080 }
        api_02 = { container_id = ccp_container_instance.api_02.id, port = 8080 }
      }
    }
    admin = {
      members = {
        admin_01 = { container_id = ccp_container_instance.admin.id, port = 4000 }
      }
    }
  }

  routes = [
    {
      listener_index   = 0 # api.example.com
      target_group_key = "api"
      priority         = 10
      policies = {
        rate_limit_per_sec = 500
        cors_enabled       = true
        cors_origins       = ["https://app.example.com"]
        cors_credentials   = true
        waf_preset         = "strict"
      }
    },
    {
      listener_index   = 1 # admin.example.com
      target_group_key = "admin"
      priority         = 10
      policies = {
        allow_cidrs = ["203.0.113.0/24"]
        basic_auth_users = [
          { user = "alice", password = var.alice_password },
          { user = "bob", password = var.bob_password },
        ]
        waf_preset = "strict"
      }
    },
  ]
}

output "url" {
  value = module.web.url   # https://api.example.com
}

output "acme_status" {
  value = module.web.listener_acme_status
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | string | yes | — | Nom de la gateway. |
| `region` | string | yes | — | `RNN` / `PAR` / `ABJ`. |
| `plan` | string | no | `"small"` | `small` / `medium` / `large`. |
| `vpc_id` | string | yes | — | UUID du VPC. |
| `vnet_id` | string | yes | — | UUID du VNet de la VIP. |
| `public_ip_id` | string | no | `null` | UUID IP publique (`null` = AppGW interne). |
| `tags` | list(string) | no | `[]` | |
| `force_https` | bool | no | `true` | |
| `hsts_enabled` | bool | no | `false` | |
| `hsts_max_age` | number | no | `31536000` | |
| `global_rate_limit_per_sec` | number | no | `null` | |
| `global_allow_cidrs` | list(string) | no | `[]` | |
| `global_deny_cidrs` | list(string) | no | `[]` | |
| `trust_proxy_headers` | bool | no | `false` | |
| `hostnames` | list(string) | yes | — | 1 listener par hostname (référencé par index dans `routes`). |
| `custom_domain` | bool | no | `false` | `true` = domaines clients (CNAME requis). |
| `target_groups` | map(object) | yes | — | Voir schéma `atomic/appgw-target-group`. |
| `routes` | list(object) | yes | — | Voir schéma ci-dessous. Le sub-champ `basic_auth_users` est marqué sensitive par l'atomic sous-jacent. |

### Schéma `routes[*]`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `listener_index` | number | required | Index dans `hostnames` (0-based). |
| `target_group_key` | string | required | Clé dans `target_groups`. |
| `priority` | number | `100` | Unique par AppGW, asc. |
| `path_match` | string | `"/"` | Pattern. |
| `path_match_type` | string | `"prefix"` | `prefix` / `exact` / `regex`. |
| `method_match` | list(string) | `[]` | |
| `strip_prefix` | bool | `false` | Strippe `path_match` avant forward backend (`/web-app/foo` → `/foo`). Mode `prefix`/`exact` uniquement. |
| `header_matches` | list(object) | `[]` | |
| `policies` | object | `{}` | Policies route-level (rate limit, CORS, headers, WAF, `basic_auth_users`). |

### Schéma `routes[*].policies.basic_auth_users[*]`

| Field | Type | Description |
|-------|------|-------------|
| `user` | string | Username (1-64). |
| `password` | string | Mot de passe en clair (1-256). Persisté en clair dans le state. |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `id` | no | UUID de la gateway. |
| `status` | no | `creating` / `active` / `error` / `deleting`. |
| `plan` | no | Plan effectif. |
| `region` | no | Région. |
| `vip_address` | no | VIP privée. |
| `public_ip_address` | no | IP publique attachée. |
| `hostnames` | no | Liste hostnames (input echo). |
| `listener_ids` | no | Map hostname → UUID. |
| `listener_acme_status` | no | Map hostname → `pending` / `issued` / `failed`. |
| `target_group_ids` | no | Map clé → UUID. |
| `target_group_member_ids` | no | Map clé → map(label → UUID member). |
| `route_ids` | no | Liste UUID routes. |
| `route_basic_auth_secret_refs` | no | Refs opaques Secret Manager par route (`null` si pas d'auth). |
| `url` | no | URL HTTPS du 1er hostname. |

## Notes

- **Ordre des hostnames stable** : `routes[*].listener_index` référence par position. Réordonner `hostnames` change la cible des routes — préférer ajouter en queue.
- **Reuse de target groups** : plusieurs routes peuvent pointer vers le même `target_group_key` (path-based avec policies différentes).
- **Custom domain** : `custom_domain=true` exige un CNAME client vers l'IP publique de la gateway **avant** apply, sinon ACME échoue.
- **`basic_auth_users` — sensibilité state** : les mots de passe sont persistés en clair. Utiliser un backend chiffré (S3+KMS, Vault, TFC). La plateforme ne les rend jamais ; au `terraform import`, les blocs sont vides et un `apply` les re-synchronise.
- **Migration depuis `exposure/web-app-with-appgw`** : signature identique côté inputs (à l'exception du nom du chemin source). Permuter `source` suffit ; pas de breaking change ni de drift d'état attendu.
