# Module `atomic/iam-role-assignment`

Wrapper minimal 1-1 autour de `ccp_iam_role_assignment`. Attache un rôle IAM CETIC Cloud à un principal (org_member, api_key, service_account, ccks_workload).

Tous les attributs forcent un replacement (pas de PATCH côté API).

## Exemple

```hcl
module "ci_can_deploy" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/iam-role-assignment?ref=v0.5.0"

  role_id        = module.registry_admin.id
  principal_type = "service_account"
  principal_id   = module.ci_sa.id
  expires_at     = "2027-05-12T00:00:00Z"
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `role_id` | string | yes | — | UUID du rôle IAM. |
| `principal_type` | string | yes | — | `org_member` / `api_key` / `service_account` / `ccks_workload`. |
| `principal_id` | string | yes | — | UUID du principal. |
| `expires_at` | string | no | `null` | RFC 3339 timestamp d'expiration. |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `id` | no | UUID de l'assignation. |
| `role_id` | no | Echo du `role_id`. |
| `principal_type` | no | Echo. |
| `principal_id` | no | Echo. |
| `expires_at` | no | RFC 3339 ou `null`. |
| `created_at` | no | RFC 3339. |
