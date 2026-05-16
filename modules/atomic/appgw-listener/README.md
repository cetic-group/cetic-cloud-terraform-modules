# Module `atomic/appgw-listener`

Wrapper 1-1 autour de `ccp_appgw_listener`. Un listener = **1 hostname** + **1 certificat Let's Encrypt** servi par une Application Gateway. Plusieurs listeners (= plusieurs hostnames) peuvent partager la même AppGW via SNI.

Pré-requis : une AppGW déjà créée (`atomic/application-gateway`).

> **🇬🇧** 1-1 wrapper around `ccp_appgw_listener`. One listener = one hostname + one auto Let's Encrypt cert. Multiple listeners share the parent AppGW via SNI.

## Exemple — sous-domaine auto (validation HTTP-01)

```hcl
module "listener_app" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/appgw-listener?ref=v0.8.0"

  appgw_id      = module.appgw.id
  hostname      = "acme-rnn.app.cloud.cetic-group.com"
  custom_domain = false   # défaut — sous-domaine auto sous app.cloud.cetic-group.com
}
```

## Exemple — domaine client (validation DNS-01, CNAME requis avant apply)

```hcl
module "listener_api" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/appgw-listener?ref=v0.8.0"

  appgw_id      = module.appgw.id
  hostname      = "api.example.com"
  custom_domain = true   # DNS-01 — CNAME api.example.com → <appgw>.app.cloud.cetic-group.com REQUIS
}

output "acme_status" {
  value = module.listener_api.acme_status   # pending → issued (~30-90s)
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `appgw_id` | string | yes | — | UUID de l'AppGW parente. **Immutable**. |
| `hostname` | string | yes | — | FQDN servi (lowercase, RFC 1123, max 253 chars). **Immutable**. |
| `custom_domain` | bool | no | `false` | `true` = domaine client (DNS-01 + CNAME requis). **Immutable**. |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `id` | no | UUID du listener. |
| `appgw_id` | no | UUID de la gateway parente. |
| `hostname` | no | Hostname effectivement servi. |
| `custom_domain` | no | `true` = domaine client. |
| `acme_status` | no | `pending` / `issued` / `failed`. |
| `acme_last_renewal_at` | no | Timestamp RFC 3339 du dernier renouvellement. |
| `cert_path` | no | Chemin filesystem informatif du cert live. |
| `created_at` | no | Timestamp RFC 3339 de création. |

## Notes

- **Tout est immutable** : `appgw_id`, `hostname`, `custom_domain`. Toute modification déclenche un destroy + create — donc une coupure brève sur ce hostname et l'émission d'un nouveau cert ACME (~30-90s en HTTP-01, plus long en DNS-01 selon le TTL).
- **`custom_domain=true` sans CNAME** : l'émission ACME échoue (`acme_status=failed`). Vérifier la propagation DNS **avant** l'apply.
- **Rate limit Let's Encrypt** : 50 certs/semaine/registered domain. Pour le développement, préférer `custom_domain=false` (sous-domaine auto = staging issuer côté plateforme).
- **Pas de cert custom** : la plateforme ne supporte pas l'upload de cert externes — uniquement Let's Encrypt. Pour un cert d'entreprise CA, ouvrir un ticket support.
