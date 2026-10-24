# Module `atomic/appgw-route`

Wrapper 1-1 autour de `ccp_appgw_route`. Une route lie un **listener** (hostname) + un **path** (avec optionnellement headers + méthode) à un **target group**. Les policies route-level (rate limit, IP allow/deny, CORS, headers, basic auth, WAF) sont déclarées ici.

Pré-requis : une AppGW déjà créée (`atomic/application-gateway`) + un listener (`atomic/appgw-listener`) + un target group (`atomic/appgw-target-group`).

> **🇬🇧** 1-1 wrapper around `ccp_appgw_route`. Connects a listener (hostname) + a path to a target group, with optional route-level policies (rate limit, IP allow/deny, CORS, headers, basic auth, WAF).

## Exemple — route minimale

```hcl
module "route_root" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/appgw-route?ref=v0.8.0"

  appgw_id        = module.appgw.id
  listener_id     = module.listener_api.id
  target_group_id = module.tg_api.id

  path_match      = "/"
  path_match_type = "prefix"
}
```

## Exemple — route avec rate limit + CORS + WAF strict

```hcl
module "route_api_v1" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/appgw-route?ref=v0.8.0"

  appgw_id        = module.appgw.id
  listener_id     = module.listener_api.id
  target_group_id = module.tg_api.id

  priority        = 10
  path_match      = "/api/v1/"
  path_match_type = "prefix"

  rate_limit_per_sec = 100
  allow_cidrs        = ["203.0.113.0/24", "198.51.100.0/24"]

  cors_enabled     = true
  cors_origins     = ["https://app.example.com"]
  cors_methods     = ["GET", "POST"]
  cors_credentials = true

  request_headers = {
    "X-Real-IP" = "%[src]"
  }

  response_headers = {
    "X-Frame-Options" = "DENY"
  }

  waf_preset = "strict"
}
```

## Exemple — route avec `strip_prefix`

Pour exposer une application sous-montée à un préfixe (`/web-app`) alors
que le backend sert depuis `/`, on demande à la gateway de retirer le
préfixe avant de forward au backend.

```hcl
module "route_web_app" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/appgw-route?ref=v0.13.0"

  appgw_id        = module.appgw.id
  listener_id     = module.listener_public.id
  target_group_id = module.tg_web.id

  path_match      = "/web-app"
  path_match_type = "prefix"
  strip_prefix    = true  # /web-app/foo → /foo côté backend
}
```

## Exemple — route avec basic auth

```hcl
module "route_admin" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/appgw-route?ref=v0.8.0"

  appgw_id        = module.appgw.id
  listener_id     = module.listener_admin.id
  target_group_id = module.tg_admin.id

  priority   = 50
  path_match = "/"

  basic_auth_users = [
    { user = "alice", password = var.alice_password },
    { user = "bob",   password = var.bob_password },
  ]

  waf_preset = "strict"
}

output "admin_secret_ref" {
  value = module.route_admin.basic_auth_secret_ref  # référence opaque du Secret Manager
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `appgw_id` | string | yes | — | UUID de l'AppGW parente. |
| `listener_id` | string | yes | — | UUID du listener. |
| `target_group_id` | string | yes | — | UUID du target group cible. |
| `priority` | number | no | `100` | Ordre d'évaluation (0-10000, unique par AppGW). |
| `path_match` | string | no | `"/"` | Pattern à matcher. |
| `path_match_type` | string | no | `"prefix"` | `prefix` / `exact` / `regex`. |
| `header_matches` | list(object) | no | `[]` | Conditions sur les headers de requête (voir schéma). |
| `method_match` | list(string) | no | `[]` | Méthodes HTTP autorisées (vide = toutes). |
| `rate_limit_per_sec` | number | no | `null` | Rate limit route-level par IP, en req/s (`null` = hérite). |
| `allow_cidrs` | list(string) | no | `[]` | CIDR autorisés. |
| `deny_cidrs` | list(string) | no | `[]` | CIDR refusés. |
| `request_headers` | map(string) | no | `{}` | Headers à set sur la requête backend. |
| `response_headers` | map(string) | no | `{}` | Headers à set sur la réponse client. |
| `cors_enabled` | bool | no | `false` | Active CORS. |
| `cors_origins` | list(string) | no | `[]` | Origins autorisées. |
| `cors_methods` | list(string) | no | `["GET","POST","PUT","DELETE","OPTIONS"]` | Méthodes CORS. |
| `cors_credentials` | bool | no | `false` | `Access-Control-Allow-Credentials`. |
| `basic_auth_users` | list(object) (sensitive) | no | `null` | Liste `{user, password}` pour activer le HTTP Basic Auth (voir Notes). |
| `waf_preset` | string | no | `"off"` | `off` / `permissive` / `strict`. |
| `strip_prefix` | bool | no | `false` | Strippe `path_match` avant forward au backend (prefix/exact uniquement). Voir Notes. |

### Schéma `header_matches[*]`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `name` | string | required | Nom du header (case-insensitive). |
| `value` | string | required | Valeur à matcher. |
| `op` | string | `"eq"` | `eq` / `ne` / `regex` / `prefix` / `suffix`. |

### Schéma `basic_auth_users[*]`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `user` | string | required | Username (1-64 chars). |
| `password` | string | required | Mot de passe en clair (1-256 chars). **Persisté dans le state Terraform.** |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `id` | no | UUID de la route. |
| `appgw_id` | no | UUID de la gateway parente. |
| `listener_id` | no | UUID du listener associé. |
| `target_group_id` | no | UUID du target group cible. |
| `priority` | no | Priorité effective. |
| `basic_auth_secret_ref` | no | Référence opaque du Secret Manager backing les credentials. `null` si pas d'auth. |

## Notes

- **Priorité unique par AppGW** — deux routes avec la même priorité = erreur API.
- **CORS `credentials` + `origins=["*"]`** : refusé par tous les navigateurs (et donc bloqué côté module via `precondition`).
- **`waf_preset=strict`** : peut bloquer des requêtes légitimes contenant `<script>`, `union select`, etc. Tester en `permissive` d'abord.
- **`basic_auth_users` — sensibilité du state** : les mots de passe sont **persistés en clair dans le state Terraform**. Utiliser un backend chiffré (S3+KMS, Vault, Terraform Cloud). La plateforme ne retourne jamais les mots de passe en clair — au `terraform import`, le bloc `basic_auth_user` est vide et un `apply` ultérieur le re-synchronise.
- **`basic_auth_secret_ref`** : référence opaque générée par la plateforme — ce n'est pas un secret en soi (impossible de l'utiliser hors plateforme) donc l'output est `sensitive=false`. Pratique pour cross-référencer la route dans une `ccp_secret` data source d'inventaire.
- **`strip_prefix`** : utile quand une app est sous-montée à un préfixe (ex. `/web-app`) alors que son backend sert depuis `/`. La gateway retire `path_match` avant de forwarder. Ignoré si `path_match` est vide ou si `path_match_type = "regex"` (impossible de stripper un motif regex). Compatible avec `prefix` et `exact`.

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
| [ccp_appgw_route.this](https://registry.terraform.io/providers/cetic-group/ccp/latest/docs/resources/appgw_route) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_cidrs"></a> [allow\_cidrs](#input\_allow\_cidrs) | CIDR autorisés (uniquement pour cette route). | `list(string)` | `[]` | no |
| <a name="input_appgw_id"></a> [appgw\_id](#input\_appgw\_id) | UUID de l'Application Gateway parente. | `string` | n/a | yes |
| <a name="input_basic_auth_users"></a> [basic\_auth\_users](#input\_basic\_auth\_users) | Liste d'identifiants `{user, password}` pour activer le HTTP Basic Auth sur la route.<br/>`null` ou `[]` désactive l'auth. Les mots de passe sont persistés **en clair** dans le state Terraform<br/>(et donc dans tout backend de state) — utiliser un backend chiffré (S3+KMS, Vault, etc.).<br/>Côté plateforme, ils sont hashés et stockés dans une entrée Secret Manager dont la référence opaque<br/>est exposée via l'output `basic_auth_secret_ref`. | <pre>list(object({<br/>    user     = string<br/>    password = string<br/>  }))</pre> | `null` | no |
| <a name="input_cache_bypass_cookies"></a> [cache\_bypass\_cookies](#input\_cache\_bypass\_cookies) | Cookies de session exclus ; liste vide = tout cookie contourne le cache. | `list(string)` | `[]` | no |
| <a name="input_cache_debug_headers"></a> [cache\_debug\_headers](#input\_cache\_debug\_headers) | Exposer X-Cache: HIT ou MISS. | `bool` | `false` | no |
| <a name="input_cache_default_ttl_s"></a> [cache\_default\_ttl\_s](#input\_cache\_default\_ttl\_s) | Durée par défaut du mode force, en secondes. | `number` | `60` | no |
| <a name="input_cache_max_ttl_s"></a> [cache\_max\_ttl\_s](#input\_cache\_max\_ttl\_s) | Durée maximale des entrées en secondes. | `number` | `3600` | no |
| <a name="input_cache_mode"></a> [cache\_mode](#input\_cache\_mode) | Politique de cache : off, respect ou force. | `string` | `"off"` | no |
| <a name="input_cors_credentials"></a> [cors\_credentials](#input\_cors\_credentials) | Si `true`, `Access-Control-Allow-Credentials: true`. Incompatible avec `cors_origins=["*"]`. | `bool` | `false` | no |
| <a name="input_cors_enabled"></a> [cors\_enabled](#input\_cors\_enabled) | Active CORS sur cette route. | `bool` | `false` | no |
| <a name="input_cors_methods"></a> [cors\_methods](#input\_cors\_methods) | Méthodes CORS autorisées. Ignoré si `cors_enabled=false`. | `list(string)` | <pre>[<br/>  "GET",<br/>  "POST",<br/>  "PUT",<br/>  "DELETE",<br/>  "OPTIONS"<br/>]</pre> | no |
| <a name="input_cors_origins"></a> [cors\_origins](#input\_cors\_origins) | Origins autorisées (ex. `["https://app.example.com"]` ou `["*"]`). Ignoré si `cors_enabled=false`. | `list(string)` | `[]` | no |
| <a name="input_deny_cidrs"></a> [deny\_cidrs](#input\_deny\_cidrs) | CIDR refusés (priorité sur allow). | `list(string)` | `[]` | no |
| <a name="input_header_matches"></a> [header\_matches](#input\_header\_matches) | Conditions sur les headers de la requête. `op` : `eq` / `ne` / `regex` / `prefix` / `suffix`. | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>    op    = optional(string, "eq")<br/>  }))</pre> | `[]` | no |
| <a name="input_listener_id"></a> [listener\_id](#input\_listener\_id) | UUID du listener (hostname + cert) auquel la route s'applique. | `string` | n/a | yes |
| <a name="input_method_match"></a> [method\_match](#input\_method\_match) | Liste des méthodes HTTP autorisées (vide = toutes). Ex. `["GET", "POST"]`. | `list(string)` | `[]` | no |
| <a name="input_path_match"></a> [path\_match](#input\_path\_match) | Pattern de match du path. Sémantique selon `path_match_type` (prefix : `/api/`; exact : `/healthz`; regex : `^/v[0-9]+/`). | `string` | `"/"` | no |
| <a name="input_path_match_type"></a> [path\_match\_type](#input\_path\_match\_type) | Mode de matching du path : `prefix` / `exact` / `regex`. | `string` | `"prefix"` | no |
| <a name="input_priority"></a> [priority](#input\_priority) | Ordre d'évaluation (entier asc — la plus basse priorité matche en premier). Doit être unique par AppGW. | `number` | `100` | no |
| <a name="input_rate_limit_per_sec"></a> [rate\_limit\_per\_sec](#input\_rate\_limit\_per\_sec) | Rate limit route-level par IP source en req/s. `null` = hérite du global de la gateway. | `number` | `null` | no |
| <a name="input_request_headers"></a> [request\_headers](#input\_request\_headers) | Headers à set sur la requête vers le backend. Ex. `{ "X-Real-IP" = "%[src]" }`. | `map(string)` | `{}` | no |
| <a name="input_response_headers"></a> [response\_headers](#input\_response\_headers) | Headers à set sur la réponse retournée au client. | `map(string)` | `{}` | no |
| <a name="input_strip_prefix"></a> [strip\_prefix](#input\_strip\_prefix) | Si `true` et `path_match` non vide (mode `prefix`/`exact`), la gateway<br/>strippe le préfixe `path_match` de l'URL avant forward au backend<br/>(ex. `/web-app/foo` devient `/foo`). Ignoré si `path_match` est vide<br/>ou si `path_match_type = "regex"`. | `bool` | `false` | no |
| <a name="input_target_group_id"></a> [target\_group\_id](#input\_target\_group\_id) | UUID du target group vers lequel la route route le trafic. | `string` | n/a | yes |
| <a name="input_waf_preset"></a> [waf\_preset](#input\_waf\_preset) | Preset WAF : `off` / `permissive` / `strict`. | `string` | `"off"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_appgw_id"></a> [appgw\_id](#output\_appgw\_id) | UUID de la gateway parente. |
| <a name="output_basic_auth_secret_ref"></a> [basic\_auth\_secret\_ref](#output\_basic\_auth\_secret\_ref) | Référence opaque du Secret Manager backing les credentials basic auth (ou `null` si<br/>`basic_auth_users` est vide). Le provider marque ce champ Sensitive, donc l'output<br/>DOIT l'être aussi (Terraform refuse "Output refers to sensitive values" sinon).<br/>L'identifiant interne n'est pas un mot de passe, mais propage la marque sensitive<br/>pour respecter le contrat provider et passer terraform test. |
| <a name="output_id"></a> [id](#output\_id) | UUID de la route. |
| <a name="output_listener_id"></a> [listener\_id](#output\_listener\_id) | UUID du listener associé. |
| <a name="output_priority"></a> [priority](#output\_priority) | Priorité effective. |
| <a name="output_target_group_id"></a> [target\_group\_id](#output\_target\_group\_id) | UUID du target group cible. |
<!-- END_TF_DOCS -->