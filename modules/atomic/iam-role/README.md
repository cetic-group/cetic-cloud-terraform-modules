# Module `atomic/iam-role`

Wrapper minimal 1-1 autour de `ccp_iam_role`. Crée un rôle IAM CETIC Cloud custom avec un PolicyDocument JSON brut.

Pour la composition ergonomique HCL (statements + conditions), utilise plutôt `modules/managed/iam-role`.

## Exemple

```hcl
module "registry_admin" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/iam-role?ref=v0.5.0"

  name        = "RegistryAdminCustom"
  description = "Push/Pull/GC sur toutes les registries du tenant"
  policy_document_json = jsonencode({
    version = "2026-05-10"
    statements = [
      {
        effect    = "Allow"
        actions   = ["registry:*"]
        resources = ["arn:ccp:registry:*:${var.tenant_id}:registry/*"]
      },
    ]
  })
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | string | yes | — | 1-64 chars, unique within the tenant. |
| `description` | string | no | `null` | Free-form description (max 512 chars). |
| `policy_document_json` | string | yes | — | Raw JSON PolicyDocument. |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `id` | no | UUID. |
| `name` | no | Name. |
| `policy_hash` | no | SHA-256 hex of the canonical PolicyDocument. |
| `policy_document_json` | no | Canonicalised JSON from the API. |
| `is_built_in` | no | Always `false`. |
| `created_at` / `updated_at` | no | RFC 3339 timestamps. |
