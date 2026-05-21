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
