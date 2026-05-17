# `atomic/support-subscription`

Manages the active CETIC support subscription for the current tenant.
Wraps `ccp_support_subscription` + the `ccp_support_plan` datasource so
that downstream modules can read the resolved SLA / price / channels in
a single block.

## Example

```hcl
module "support" {
  source   = "../../modules/atomic/support-subscription"
  plan_key = "standard"
}

output "support_sla_first_response_hours" {
  value = module.support.sla_first_response_hours
}
```

## Inputs

| Name       | Type   | Required | Default | Description                                |
|------------|--------|----------|---------|--------------------------------------------|
| `plan_key` | string | **yes**  | —       | `base` / `standard` / `premium` / custom.  |

## Outputs

| Name                       | Type           | Description                                  |
|----------------------------|----------------|----------------------------------------------|
| `id`                       | string         | Subscription row UUID.                       |
| `tenant_id`                | string         | Tenant UUID.                                 |
| `plan_key`                 | string         | Effective plan key.                          |
| `started_at`               | string         | RFC3339 subscription start timestamp.        |
| `display_name`             | string         | Human-readable plan name.                    |
| `price_eur_month`          | number         | Monthly price (EUR), `0` for free.           |
| `sla_first_response_hours` | number         | First-response SLA (hours).                  |
| `sla_resolution_hours`     | number         | Resolution SLA (`0` = best-effort).          |
| `max_priority`             | string         | Maximum ticket priority allowed.             |
| `channels`                 | list(string)   | Supported channels (`email`/`chat`/`phone`). |

## Notes

- Only **one** active subscription per tenant — apply the module at most
  once per workspace.
- Destroying the module downgrades to the default `base` (free) plan.
- Switching to a paid plan requires a payment method on file; the apply
  will fail with `402 Payment Required` otherwise (add a card via the
  console first).
