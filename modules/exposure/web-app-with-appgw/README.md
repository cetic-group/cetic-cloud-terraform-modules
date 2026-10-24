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

## Cache HTTP (provider 7.3+)

Cette version dépend de la publication du provider avec cetic-cloud-platform#1733 et de l’API correspondante. Aucun tag n’est publié par cette feature.

Activez `cache_enabled` sur la passerelle ; `cache_size_mb` est le budget demandé partagé entre les routes, `cache_max_object_kb` limite les objets. Les outputs `cache_effective_size_mb` et `cache_size_limit_mb` exposent le budget appliqué et le plafond après un changement de plan.

Les routes acceptent `cache_mode` (`off`, `respect`, `force`), `cache_default_ttl_s` (60), `cache_max_ttl_s` (3600), `cache_bypass_cookies` (liste vide : exclure tous les cookies) et `cache_debug_headers` (false). Dans les modules composés, ces attributs sont directement sur chaque objet `routes`, au même niveau que `path_match`.

Seuls les GET publics en 200 alimentent le cache ; HEAD peut lire ces entrées. Authorization, Set-Cookie et les directives privées sont toujours exclus. Vary: Accept-Language contourne le cache. Il n’y a pas de ressource Terraform de purge : utiliser l’API, la console ou `cetic appgw cache purge`.

> **EN:** Gateway settings control a shared cache budget; route settings opt public responses into caching. The requested budget remains stable after resizing, while computed outputs report the effective limit. API and provider support for #1733 are required. Purging is an imperative API/CLI action.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7 |
| <a name="requirement_ccp"></a> [ccp](#requirement\_ccp) | >= 7.3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_ccp"></a> [ccp](#provider\_ccp) | 7.3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_gateway"></a> [gateway](#module\_gateway) | ../../atomic/application-gateway | n/a |
| <a name="module_routes"></a> [routes](#module\_routes) | ../../atomic/appgw-route | n/a |
| <a name="module_target_groups"></a> [target\_groups](#module\_target\_groups) | ../../atomic/appgw-target-group | n/a |

## Resources

| Name | Type |
|------|------|
| [ccp_appgw_listener.this](https://registry.terraform.io/providers/cetic-group/ccp/latest/docs/resources/appgw_listener) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acme_challenge"></a> [acme\_challenge](#input\_acme\_challenge) | Type de challenge ACME (Let's Encrypt) appliqué à tous les listeners (hostnames) :<br/>`http01` (défaut) ou `dns01`. `null` = aucun certificat TLS émis.<br/>`dns01` requiert `acme_dns_provider` + `acme_dns_credentials` (et un CNAME du domaine client). | `string` | `"http01"` | no |
| <a name="input_acme_dns_credentials"></a> [acme\_dns\_credentials](#input\_acme\_dns\_credentials) | Credentials du provider DNS pour `dns01` (write-only). Requis si `acme_challenge = "dns01"`. | `map(string)` | `null` | no |
| <a name="input_acme_dns_provider"></a> [acme\_dns\_provider](#input\_acme\_dns\_provider) | Clé du provider DNS pour `dns01` (ex. `cloudflare`). Requis si `acme_challenge = "dns01"`. | `string` | `null` | no |
| <a name="input_cache_enabled"></a> [cache\_enabled](#input\_cache\_enabled) | Activer le cache HTTP public de la passerelle. | `bool` | `false` | no |
| <a name="input_cache_max_object_kb"></a> [cache\_max\_object\_kb](#input\_cache\_max\_object\_kb) | Taille maximale des objets en Kio. | `number` | `512` | no |
| <a name="input_cache_size_mb"></a> [cache\_size\_mb](#input\_cache\_size\_mb) | Budget demandé en Mio, partagé entre les routes actives et borné par le plan. | `number` | `64` | no |
| <a name="input_force_https"></a> [force\_https](#input\_force\_https) | n/a | `bool` | `true` | no |
| <a name="input_global_allow_cidrs"></a> [global\_allow\_cidrs](#input\_global\_allow\_cidrs) | n/a | `list(string)` | `[]` | no |
| <a name="input_global_deny_cidrs"></a> [global\_deny\_cidrs](#input\_global\_deny\_cidrs) | n/a | `list(string)` | `[]` | no |
| <a name="input_global_rate_limit_per_sec"></a> [global\_rate\_limit\_per\_sec](#input\_global\_rate\_limit\_per\_sec) | n/a | `number` | `null` | no |
| <a name="input_hostnames"></a> [hostnames](#input\_hostnames) | Liste ordonnée de hostnames à exposer. 1 listener (et 1 cert ACME Let's Encrypt)<br/>par hostname. Les routes référencent les listeners par leur **index** dans cette liste<br/>via `routes[*].listener_index`.<br/><br/>Exemple : `["api.example.com", "admin.example.com"]` → index 0, 1. | `list(string)` | n/a | yes |
| <a name="input_hsts_enabled"></a> [hsts\_enabled](#input\_hsts\_enabled) | n/a | `bool` | `false` | no |
| <a name="input_hsts_max_age"></a> [hsts\_max\_age](#input\_hsts\_max\_age) | n/a | `number` | `31536000` | no |
| <a name="input_name"></a> [name](#input\_name) | Nom de base de la gateway. Les listeners/target groups/routes en sont dérivés ou nommés via leur clé. | `string` | n/a | yes |
| <a name="input_plan"></a> [plan](#input\_plan) | Plan AppGW. Clés canoniques : `appgw-small` / `appgw-medium` / `appgw-large` (alias `small`/`medium`/`large` acceptés). | `string` | `"appgw-small"` | no |
| <a name="input_public_ip_id"></a> [public\_ip\_id](#input\_public\_ip\_id) | UUID de l'IP publique à attacher. `null` = gateway interne. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Région CETIC Cloud : `RNN` / `PAR` / `ABJ`. | `string` | n/a | yes |
| <a name="input_routes"></a> [routes](#input\_routes) | Liste de routes. Chaque route référence :<br/>- un listener par index (`listener_index` → `hostnames[listener_index]`)<br/>- un target group par clé (`target_group_key` → clé de `target_groups`)<br/><br/>Policies route-level optionnelles via `policies` object. | <pre>list(object({<br/>    listener_index       = number<br/>    target_group_key     = string<br/>    priority             = optional(number, 100)<br/>    path_match           = optional(string, "/")<br/>    path_match_type      = optional(string, "prefix")<br/>    method_match         = optional(list(string), [])<br/>    strip_prefix         = optional(bool, false)<br/>    cache_mode           = optional(string, "off")<br/>    cache_default_ttl_s  = optional(number, 60)<br/>    cache_max_ttl_s      = optional(number, 3600)<br/>    cache_bypass_cookies = optional(list(string), [])<br/>    cache_debug_headers  = optional(bool, false)<br/><br/>    header_matches = optional(list(object({<br/>      name  = string<br/>      value = string<br/>      op    = optional(string, "eq")<br/>    })), [])<br/>    policies = optional(object({<br/>      rate_limit_per_sec = optional(number)<br/>      allow_cidrs        = optional(list(string), [])<br/>      deny_cidrs         = optional(list(string), [])<br/>      request_headers    = optional(map(string), {})<br/>      response_headers   = optional(map(string), {})<br/>      cors_enabled       = optional(bool, false)<br/>      cors_origins       = optional(list(string), [])<br/>      cors_methods       = optional(list(string), ["GET", "POST", "PUT", "DELETE", "OPTIONS"])<br/>      cors_credentials   = optional(bool, false)<br/>      basic_auth_users = optional(list(object({<br/>        user     = string<br/>        password = string<br/>      })))<br/>      waf_preset = optional(string, "off")<br/>    }), {})<br/>  }))</pre> | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `list(string)` | `[]` | no |
| <a name="input_target_groups"></a> [target\_groups](#input\_target\_groups) | Map de target groups. Clé = label logique (référencé par `routes[*].target_group_key`).<br/>Au moins une entrée requise (typiquement `default`).<br/><br/>Champs :<br/>- `algorithm` : `roundrobin` / `leastconn` / `source` / `random` (défaut `roundrobin`).<br/>- `health_check` : object (cf. atomic/appgw-target-group).<br/>- `sticky_enabled` / `sticky_cookie_name` : optionnels.<br/>- `members` : map(object) (cf. atomic/appgw-target-group). | <pre>map(object({<br/>    algorithm = optional(string, "roundrobin")<br/>    health_check = optional(object({<br/>      protocol            = optional(string, "http")<br/>      method              = optional(string, "GET")<br/>      path                = optional(string, "/")<br/>      expect_status       = optional(number, 200)<br/>      interval_sec        = optional(number, 5)<br/>      timeout_sec         = optional(number, 3)<br/>      healthy_threshold   = optional(number, 2)<br/>      unhealthy_threshold = optional(number, 3)<br/>    }), {})<br/>    sticky_enabled     = optional(bool, false)<br/>    sticky_cookie_name = optional(string)<br/>    members = map(object({<br/>      container_id   = optional(string)<br/>      vm_instance_id = optional(string)<br/>      target_ip      = optional(string)<br/>      port           = number<br/>      weight         = optional(number, 100)<br/>      enabled        = optional(bool, true)<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_vnet_id"></a> [vnet\_id](#input\_vnet\_id) | UUID du VNet hébergeant la VIP. | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | UUID du VPC. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_appgw_id"></a> [appgw\_id](#output\_appgw\_id) | UUID de l'Application Gateway créée. |
| <a name="output_cache_effective_size_mb"></a> [cache\_effective\_size\_mb](#output\_cache\_effective\_size\_mb) | Budget du cache en Mio. |
| <a name="output_cache_size_limit_mb"></a> [cache\_size\_limit\_mb](#output\_cache\_size\_limit\_mb) | Budget du cache en Mio. |
| <a name="output_hostnames"></a> [hostnames](#output\_hostnames) | Liste des hostnames exposés (même ordre que l'input). |
| <a name="output_listener_ids"></a> [listener\_ids](#output\_listener\_ids) | Map keyed par hostname → UUID listener. |
| <a name="output_public_ip"></a> [public\_ip](#output\_public\_ip) | IP publique attachée, ou `null`. |
| <a name="output_route_ids"></a> [route\_ids](#output\_route\_ids) | Liste des UUID des routes, dans l'ordre déclaré. |
| <a name="output_status"></a> [status](#output\_status) | Statut courant de la gateway. |
| <a name="output_target_group_ids"></a> [target\_group\_ids](#output\_target\_group\_ids) | Map keyed par clé logique → UUID target group. |
| <a name="output_url"></a> [url](#output\_url) | URL canonique HTTPS (premier hostname). |
| <a name="output_vip_address"></a> [vip\_address](#output\_vip\_address) | VIP privée de la gateway dans le VNet. |
<!-- END_TF_DOCS -->