# Module `atomic/application-gateway`

Wrapper 1-1 autour de la resource provider `ccp_application_gateway`. Provisionne une **Application Gateway L7** (HTTP/HTTPS) avec terminaison TLS automatique, routing host/path et policies (rate limit, IP allow/deny, HSTS, CORS, headers, WAF) — pendant L7 du module `exposure/load-balancer` (qui reste pour le TCP/UDP brut).

Une AppGW = 1 IP publique flottante. Plusieurs hostnames partagent l'IP via SNI ; les routes (path + host + headers) sont déclarées séparément via `atomic/appgw-route`, les pools de backends via `atomic/appgw-target-group`.

> **🇬🇧** 1-1 wrapper around `ccp_application_gateway`. Provisions a L7 Application Gateway (HTTP/HTTPS) with TLS termination, host/path routing, and policies (rate limit, IP allow/deny, HSTS, CORS, headers, WAF). Pair with `atomic/appgw-route` and `atomic/appgw-target-group`. For raw TCP/UDP, use `exposure/load-balancer` instead.

## Exemple — minimal

```hcl
module "appgw_public_ip" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/public-ip?ref=v0.8.0"
  region = "RNN"
}

module "appgw" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/application-gateway?ref=v0.8.0"

  name         = "web-appgw"
  region       = "RNN"
  plan         = "medium"
  vpc_id       = module.vpc.vpc_id
  vnet_id      = module.vpc.vnet_ids.web
  public_ip_id = module.appgw_public_ip.id

  force_https   = true
  hsts_enabled  = true
  hsts_max_age  = 31536000
  tags          = ["env:prod", "team:web"]
}

output "appgw_url" {
  value = "https://${module.appgw.public_ip_address}"
}
```

## Exemple — gateway interne avec rate limit et allow-list

```hcl
module "appgw_internal" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/application-gateway?ref=v0.8.0"

  name        = "internal-api-appgw"
  region      = "RNN"
  plan        = "small"
  vpc_id      = module.vpc.vpc_id
  vnet_id     = module.vpc.vnet_ids.api
  public_ip_id = null            # gateway interne — pas d'IP publique

  global_rate_limit_per_sec = 200
  global_allow_cidrs        = ["10.0.0.0/8", "192.168.0.0/16"]
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | string | yes | — | Nom de la gateway (1-100 chars). |
| `region` | string | yes | — | `RNN` / `PAR` / `ABJ`. |
| `plan` | string | no | `"small"` | `small` / `medium` / `large`. |
| `vpc_id` | string | yes | — | UUID du VPC. |
| `vnet_id` | string | yes | — | UUID du VNet hébergeant la VIP. |
| `public_ip_id` | string | no | `null` | UUID de l'IP publique à attacher. `null` = AppGW interne. |
| `force_https` | bool | no | `true` | Redirection HTTP → HTTPS. |
| `hsts_enabled` | bool | no | `false` | Active l'en-tête HSTS. |
| `hsts_max_age` | number | no | `31536000` | `max-age` HSTS en secondes (0-63072000). |
| `global_rate_limit_per_sec` | number | no | `null` | Rate limit global par IP, en req/s. |
| `global_allow_cidrs` | list(string) | no | `[]` | CIDR autorisés globalement. |
| `global_deny_cidrs` | list(string) | no | `[]` | CIDR refusés globalement (priorité sur allow). |
| `trust_proxy_headers` | bool | no | `false` | Accepte `X-Forwarded-For` en entrée. |
| `tags` | list(string) | no | `[]` | Tags (max 60, max 50 chars). |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `id` | no | UUID de la gateway. |
| `name` | no | Nom. |
| `status` | no | `creating` / `active` / `error` / `deleting`. |
| `vip_address` | no | VIP privée dans le VNet. |
| `public_ip_address` | no | IP publique attachée, ou `null`. |
| `plan` | no | Plan effectif. |
| `region` | no | Région. |

## Notes

- Provisioning asynchrone (3-5 min en moyenne). Le provider attend `status=active`.
- HA inter-node automatique (failover sans intervention).
- Pour les listeners (hostnames + cert ACME) et routes, créer les ressources `ccp_appgw_listener` et utiliser le module `atomic/appgw-route`.
- Pour les pools de backends, utiliser `atomic/appgw-target-group`.
- Le plan détermine routes max / listeners max / rate limit max (voir documentation produit pour les bornes exactes).

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

No modules.

## Resources

| Name | Type |
|------|------|
| [ccp_application_gateway.this](https://registry.terraform.io/providers/cetic-group/ccp/latest/docs/resources/application_gateway) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cache_enabled"></a> [cache\_enabled](#input\_cache\_enabled) | Activer le cache HTTP public de la passerelle. | `bool` | `false` | no |
| <a name="input_cache_max_object_kb"></a> [cache\_max\_object\_kb](#input\_cache\_max\_object\_kb) | Taille maximale des objets en Kio. | `number` | `512` | no |
| <a name="input_cache_size_mb"></a> [cache\_size\_mb](#input\_cache\_size\_mb) | Budget demandé en Mio, partagé entre les routes actives et borné par le plan. | `number` | `64` | no |
| <a name="input_force_https"></a> [force\_https](#input\_force\_https) | Si `true`, redirige automatiquement `:80` vers `:443` (sauf challenges ACME). | `bool` | `true` | no |
| <a name="input_global_allow_cidrs"></a> [global\_allow\_cidrs](#input\_global\_allow\_cidrs) | Liste de CIDR autorisés globalement. Vide = pas de filtrage allow-list. Exclu mutuellement avec `global_deny_cidrs` au niveau du même CIDR. | `list(string)` | `[]` | no |
| <a name="input_global_deny_cidrs"></a> [global\_deny\_cidrs](#input\_global\_deny\_cidrs) | Liste de CIDR refusés globalement (priorité sur allow). | `list(string)` | `[]` | no |
| <a name="input_global_rate_limit_per_sec"></a> [global\_rate\_limit\_per\_sec](#input\_global\_rate\_limit\_per\_sec) | Rate limit global par IP source en requêtes/seconde (`null` = pas de limite globale). Borné par le plan. | `number` | `null` | no |
| <a name="input_hsts_enabled"></a> [hsts\_enabled](#input\_hsts\_enabled) | Active l'en-tête `Strict-Transport-Security` sur les réponses HTTPS. | `bool` | `false` | no |
| <a name="input_hsts_max_age"></a> [hsts\_max\_age](#input\_hsts\_max\_age) | Valeur `max-age` HSTS en secondes (défaut 1 an). | `number` | `31536000` | no |
| <a name="input_name"></a> [name](#input\_name) | Nom de l'Application Gateway (1-100 caractères). | `string` | n/a | yes |
| <a name="input_plan"></a> [plan](#input\_plan) | Plan de l'AppGW. Clés canoniques de l'API : `appgw-small` / `appgw-medium` / `appgw-large`.<br/>Les formes courtes `small` / `medium` / `large` sont acceptées en alias et normalisées<br/>vers la clé canonique avant l'appel API. Détermine routes max, listeners max, rate limit max, WAF. | `string` | `"appgw-small"` | no |
| <a name="input_public_ip_id"></a> [public\_ip\_id](#input\_public\_ip\_id) | UUID d'une IP publique (même région) à attacher à l'AppGW. `null` = gateway purement interne (utile pour API privées entre VNets). | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Région CETIC Cloud : `RNN`, `PAR` ou `ABJ`. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Liste de tags free-form (max 60, max 50 chars chacun). | `list(string)` | `[]` | no |
| <a name="input_trust_proxy_headers"></a> [trust\_proxy\_headers](#input\_trust\_proxy\_headers) | Si `true`, accepte les en-têtes `X-Forwarded-For` / `X-Real-IP` en entrée (à activer uniquement si l'AppGW est derrière un autre proxy de confiance). | `bool` | `false` | no |
| <a name="input_vnet_id"></a> [vnet\_id](#input\_vnet\_id) | UUID du VNet où héberger la VIP de l'AppGW. Les backends doivent être joignables depuis ce VNet. | `string` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | UUID du VPC dans lequel héberger la gateway. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cache_effective_size_mb"></a> [cache\_effective\_size\_mb](#output\_cache\_effective\_size\_mb) | Budget du cache en Mio. |
| <a name="output_cache_size_limit_mb"></a> [cache\_size\_limit\_mb](#output\_cache\_size\_limit\_mb) | Budget du cache en Mio. |
| <a name="output_id"></a> [id](#output\_id) | UUID de l'Application Gateway. |
| <a name="output_name"></a> [name](#output\_name) | Nom de l'AppGW. |
| <a name="output_plan"></a> [plan](#output\_plan) | Plan effectif appliqué (`small` / `medium` / `large`). |
| <a name="output_public_ip_address"></a> [public\_ip\_address](#output\_public\_ip\_address) | IP publique attachée, ou `null` si gateway interne. |
| <a name="output_region"></a> [region](#output\_region) | Région de la gateway. |
| <a name="output_status"></a> [status](#output\_status) | Statut courant : `creating`, `active`, `error`, `deleting`. |
| <a name="output_vip_address"></a> [vip\_address](#output\_vip\_address) | VIP privée flottante de la gateway (dans le VNet). |
<!-- END_TF_DOCS -->