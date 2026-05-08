# Module `atomic/org-member`

Wrapper minimal autour de `ccp_org_member` — invite un utilisateur dans l'organisation avec un rôle.

## Exemple

```hcl
module "alice" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/org-member?ref=v0.1.0"

  email = "alice@acme.example.com"
  role  = "admin"
}

module "bob" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/org-member?ref=v0.1.0"

  email = "bob@acme.example.com"
  role  = "viewer"
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `email` | string | yes | Email à inviter. |
| `role` | string | yes | `admin`, `member` ou `viewer`. |

## Outputs

| Name | Description |
|------|-------------|
| `id` | UUID du membre. |
| `accepted` | `true` si l'utilisateur a déjà un compte CCP. |
| `accepted_at` | Timestamp d'acceptation. |

## Notes

- Si l'utilisateur n'a pas encore de compte CCP, la ligne reste pending et sera attachée automatiquement à son prochain login.
- Le rôle `owner` n'est pas attribuable — réservé au propriétaire racine.
