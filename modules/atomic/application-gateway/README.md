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
