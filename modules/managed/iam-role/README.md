# managed/iam-role

Module Terraform pour un **CETIC Cloud IAM custom role** (Roles v1, modèle AWS IAM-style).

Le module accepte deux modes d'entrée mutuellement exclusifs :

- **`statements`** — composition ergonomique via blocs HCL (effect/actions/resources/conditions).
  Le module compose le document via la datasource `ccp_iam_policy_document` puis l'attache à
  `ccp_iam_role.policy_document_json`.
- **`policy_document_json`** — passthrough direct d'un JSON brut (utile quand le document est
  généré par une autre source : `jsonencode(...)`, `file(...)`, etc.).

Exactement un des deux doit être fourni (XOR — validé par une `precondition`).

## Exemple minimal

```hcl
module "registry_deployer" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/managed/iam-role?ref=v0.5.0"

  name        = "RegistryDeployer"
  description = "Push autorisé sur la registry prod uniquement."

  statements = [
    {
      effect    = "Allow"
      actions   = ["registry:Push", "registry:Pull"]
      resources = ["arn:ccp:registry:rnn:${var.tenant_id}:registry/prod-*"]
    },
  ]
}
```

## Exemple complet — conditions, multi-statement, Deny

```hcl
module "billing_viewer" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/managed/iam-role?ref=v0.5.0"

  name        = "BillingViewer"
  description = "Lecture seule billing depuis les IPs CETIC."

  statements = [
    {
      sid       = "AllowBillingRead"
      effect    = "Allow"
      actions   = ["billing:Get*", "billing:List*"]
      resources = ["arn:ccp:billing:::${var.tenant_id}:*"]
      conditions = [
        {
          test     = "IpAddress"
          variable = "SourceIp"
          values   = ["203.0.113.0/24"]
        },
      ]
    },
    {
      sid       = "DenyDelete"
      effect    = "Deny"
      actions   = ["billing:Delete*", "billing:Update*"]
      resources = ["*"]
    },
  ]
}
```

## Exemple — passthrough JSON

```hcl
module "from_json" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/managed/iam-role?ref=v0.5.0"

  name                 = "FromJsonRole"
  policy_document_json = file("${path.module}/policies/registry-admin.json")
}
```

## Inputs

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `name` | string | yes | — | 1-64 chars, unique within the tenant. |
| `description` | string | no | `null` | Free-form description (max 512 chars). |
| `statements` | list(object) | conditional | `null` | Statement blocks (effect/actions/resources/sid/conditions). Mutually exclusive with `policy_document_json`. |
| `policy_document_json` | string | conditional | `null` | Raw JSON PolicyDocument. Mutually exclusive with `statements`. |

### Schéma `statements[*]`

| Field | Type | Required | Default | Description |
|---|---|---|---|---|
| `effect` | string | no | `"Allow"` | `"Allow"` or `"Deny"`. |
| `actions` | list(string) | yes | — | Non-empty. Wildcards allowed (`registry:*`, `*:Get*`). |
| `resources` | list(string) | yes | — | Non-empty. ARN patterns. |
| `sid` | string | no | `null` | Optional statement label. |
| `conditions` | list(object) | no | `[]` | List of `{ test, variable, values }`. |

## Outputs

| Name | Sensitive | Description |
|---|---|---|
| `id` / `role_id` | no | UUID of the role (alias). |
| `role_name` | no | Human-readable name. |
| `role_arn` | no | Convenience ARN `arn:ccp:iam:::role/<name>` (note: empty tenant_id segment — resolved server-side). |
| `policy_hash` | no | SHA-256 hex of the canonical PolicyDocument. |
| `policy_document_json` | no | Canonicalised JSON returned by the API. |
| `is_built_in` | no | Always `false`. |
| `created_at` / `updated_at` | no | RFC 3339 timestamps. |

## Notes

- The API canonicalises the document via JCS RFC 8785 — the order of keys you write in HCL
  may differ from what's returned. The provider's `JSONNormalizeEqual` plan modifier
  suppresses spurious diffs.
- Cross-tenant ARNs in `resources` are rejected server-side. A custom role can only
  reference its caller's tenant_id or wildcard `*`.
- Self-elevation is forbidden — a custom role cannot include `iam:AttachRole`,
  `iam:CreateRole`, `iam:UpdateRole`, `iam:DeleteRole`, `iam:DetachRole`, `iam:*` or `*`.
  Only `iam:Get*`, `iam:List*`, `iam:Simulate*` are allowed.
- The 10 platform built-in roles (`AdminAll`, `ReadOnlyAll`, `Member`, `RegistryAdmin`,
  `RegistryReader`, `BucketReader`, `BucketWriter`, `K8sViewer`, `BillingReader`,
  `NetworkAdmin`) are **not** manageable through this module — use the
  `data "ccp_iam_role"` data source to look them up.
