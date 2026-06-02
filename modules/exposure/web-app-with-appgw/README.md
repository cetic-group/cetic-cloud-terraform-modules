# Module `exposure/web-app-with-appgw`

Composable de haut-niveau qui provisionne une stack **Application Gateway L7 complète** en un seul `module` block :

- 1 `application_gateway` (via `atomic/application-gateway`)
- N listeners (1 par hostname dans `hostnames`)
- M target groups (avec leurs members, via `atomic/appgw-target-group`)
- K routes (qui aiguillent un listener + path vers un target group, via `atomic/appgw-route`)

C'est le pendant L7 du module `exposure/load-balancer` (qui reste pour TCP/UDP brut).

> **🇬🇧** High-level composable that bundles `application_gateway` + listeners + target groups + routes in a single module call. The L7 counterpart of `exposure/load-balancer`.

## Exemple — API + admin avec routing path-based

```hcl
module "appgw_public_ip" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/public-ip?ref=v0.8.0"
  region = "RNN"
}

module "web" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/exposure/web-app-with-appgw?ref=v0.8.0"

  name         = "acme-web"
  region       = "RNN"
  plan         = "medium"
  vpc_id       = module.vpc.vpc_id
  vnet_id      = module.vpc.vnet_ids.web
  public_ip_id = module.appgw_public_ip.id

  hostnames      = ["api.example.com", "admin.example.com"]
  acme_challenge = "http01" # certs Let's Encrypt — CNAME vers la gateway requis avant apply

  hsts_enabled = true

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
      listener_index   = 0           # api.example.com
      target_group_key = "api"
      priority         = 10
      path_match       = "/"
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
      path_match       = "/"
      policies = {
        allow_cidrs = ["203.0.113.0/24"]
        basic_auth_users = [
          { user = "alice", password = var.alice_password },
        ]
        waf_preset = "strict"
      }
    },
  ]
}

output "appgw_url" {
  value = module.web.url
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
| `public_ip_id` | string | no | `null` | UUID IP publique (null = AppGW interne). |
| `tags` | list(string) | no | `[]` | |
| `force_https` | bool | no | `true` | |
| `hsts_enabled` | bool | no | `false` | |
| `hsts_max_age` | number | no | `31536000` | |
| `global_rate_limit_per_sec` | number | no | `null` | |
| `global_allow_cidrs` | list(string) | no | `[]` | |
| `global_deny_cidrs` | list(string) | no | `[]` | |
| `hostnames` | list(string) | yes | — | 1 par listener (référencé par index dans `routes`). |
| `acme_challenge` | string | no | `"http01"` | `http01` / `dns01` / `null` (pas de cert). Appliqué à tous les hostnames. |
| `acme_dns_provider` | string | no | `null` | Clé provider DNS pour `dns01` (ex. `cloudflare`). |
| `acme_dns_credentials` | map(string) | no | `null` | Credentials DNS pour `dns01` (sensible, write-only). |
| `target_groups` | map(object) | yes | — | Voir schéma `atomic/appgw-target-group`. |
| `routes` | list(object) | yes | — | Voir schéma ci-dessous. |

### Schéma `routes[*]`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `listener_index` | number | required | Index dans `hostnames` (0-based). |
| `target_group_key` | string | required | Clé dans `target_groups`. |
| `priority` | number | `100` | Ordre asc, unique par AppGW. |
| `path_match` | string | `"/"` | Pattern. |
| `path_match_type` | string | `"prefix"` | `prefix` / `exact` / `regex`. |
| `method_match` | list(string) | `[]` | |
| `strip_prefix` | bool | `false` | Strippe `path_match` avant forward backend (`/web-app/foo` → `/foo`). Mode `prefix`/`exact` uniquement. |
| `header_matches` | list(object) | `[]` | |
| `policies` | object | `{}` | Policies route-level (rate limit, CORS, headers, WAF, basic auth). |

## Outputs

| Name | Description |
|------|-------------|
| `appgw_id` | UUID de la gateway. |
| `status` | Statut. |
| `vip_address` | VIP privée. |
| `public_ip` | IP publique attachée. |
| `hostnames` | Liste hostnames. |
| `listener_ids` | Map hostname → UUID. |
| `target_group_ids` | Map clé → UUID. |
| `route_ids` | Liste UUID routes. |
| `url` | URL HTTPS du 1er hostname. |

## Notes

- **Ordre des hostnames stable** : `routes[*].listener_index` est résolu par position dans `hostnames`. Réordonner la liste change la cible des routes — préférer ajouter en queue.
- **Reuse des target groups** : plusieurs routes peuvent pointer vers le même `target_group_key` (cas typique : routing path-based vers un même backend pool sous conditions différentes).
- **ACME** : `http01` exige que le hostname résolve vers l'IP publique de la gateway (CNAME/A) **avant** l'apply. `dns01` exige `acme_dns_provider` + `acme_dns_credentials` (pas de pré-requis DNS A/CNAME). `acme_challenge = null` n'émet aucun certificat.
