# Module `atomic/api-key`

Wrapper minimal autour de `ccp_api_key`. Crée une clé API CETIC Cloud (préfixée `ccp_live_…`) avec scopes contrôlés.

## Exemple

```hcl
module "ci_key" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/api-key?ref=v0.1.0"

  name            = "ci-deploy"
  scopes          = ["read", "write"]
  expires_in_days = 90
}

# Le token complet est sensible et visible une seule fois
output "ci_token" {
  value     = module.ci_key.token
  sensitive = true
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | string | yes | — | Nom (1-100 chars). |
| `scopes` | list(string) | yes | — | Au moins un parmi `read`, `write`, `billing`, `admin`. |
| `expires_in_days` | number | no | `null` | 1-3650, ou `null` = sans expiration. |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `id` | no | UUID. |
| `prefix` | no | `ccp_live_xxxxxxxx` — pour identification. |
| `token` | **yes** | Token complet, **affiché une seule fois**. |
