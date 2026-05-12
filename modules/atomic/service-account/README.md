# Module `atomic/service-account`

Wrapper minimal 1-1 autour de `ccp_service_account`. Crée un service account CETIC Cloud — identité machine token-based (`ccp_sa_*`) qui dérive ses permissions des role assignments IAM.

Différence vs `ccp_api_key` :
- API keys ont un scope statique (`read`/`write`/`billing`/`admin`).
- Service accounts n'ont **pas** de scope — leurs permissions sont uniquement celles des rôles attachés via `ccp_iam_role_assignment` avec `principal_type = "service_account"`.

## Exemple

```hcl
module "ci_pipeline" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/service-account?ref=v0.5.0"

  name        = "ci-pipeline"
  description = "GitHub Actions deploy bot"
  expires_at  = "2027-05-12T00:00:00Z"
}

# Le token complet est sensible et visible une seule fois
output "ci_token" {
  value     = module.ci_pipeline.token
  sensitive = true
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | string | yes | — | 1-64 chars, unique within the tenant. |
| `description` | string | no | `null` | Free-form description (max 512 chars). |
| `expires_at` | string | no | `null` | RFC 3339 timestamp d'expiration. |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `id` | no | UUID — utilisable comme `principal_id` dans un `ccp_iam_role_assignment`. |
| `name` | no | Nom du SA. |
| `token_prefix` | no | `ccp_sa_xxxxxxxx` (sûr à logger). |
| `token` | **yes** | Token complet, **affiché une seule fois** à la création. |
| `expires_at` | no | RFC 3339 ou `null`. |
| `last_used_at` | no | RFC 3339 ou `null`. |
| `rotated_at` | no | RFC 3339 ou `null` (toujours `null` côté TF — rotation via taint). |
| `created_at` | no | RFC 3339. |

## Notes

- Le token n'est **jamais ré-émis** par l'API après la création. Le state Terraform doit être sécurisé (backend chiffré, accès restreint).
- Pour rotater le token : `terraform taint module.<this>.ccp_service_account.this` puis `terraform apply`.
- `name`, `description` et `expires_at` sont mutables in-place (PATCH), pas de replacement.
