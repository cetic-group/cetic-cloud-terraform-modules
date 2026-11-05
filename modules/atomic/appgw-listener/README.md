# Module `atomic/appgw-listener`

Wrapper 1-1 autour de `ccp_appgw_listener`. Un listener = **1 hostname** + (optionnellement) **1 certificat Let's Encrypt** servi par une Application Gateway. Plusieurs listeners (= plusieurs hostnames) peuvent partager la même AppGW via SNI.

Pré-requis : une AppGW déjà créée (`atomic/application-gateway`).

> **🇬🇧** 1-1 wrapper around `ccp_appgw_listener`. One listener = one hostname + an optional auto Let's Encrypt cert (ACME). Multiple listeners share the parent AppGW via SNI.

## Exemple — challenge HTTP-01

```hcl
module "listener_api" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/appgw-listener?ref=v0.23.0"

  appgw_id       = module.appgw.id
  hostname       = "api.example.com"
  acme_challenge = "http01" # la gateway doit être joignable sur :80 pour ce hostname
}
```

## Exemple — challenge DNS-01 (provider DNS)

```hcl
variable "cloudflare_token" {
  type      = string
  sensitive = true
}

module "listener_admin" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/appgw-listener?ref=v0.23.0"

  appgw_id          = module.appgw.id
  hostname          = "admin.example.com"
  acme_challenge    = "dns01"
  acme_dns_provider = "cloudflare"
  acme_dns_credentials = {
    api_token = var.cloudflare_token
  }
}

output "acme_status" {
  value = module.listener_admin.acme_status # pending → issued
}
```

## Exemple — sans certificat

```hcl
module "listener_plain" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/appgw-listener?ref=v0.23.0"

  appgw_id = module.appgw.id
  hostname = "plain.app.cloud.cetic-group.com"
  # acme_challenge non défini → aucun cert TLS émis pour ce listener.
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `appgw_id` | string | yes | — | UUID de l'AppGW parente. **Immutable**. |
| `hostname` | string | yes | — | FQDN servi (lowercase, RFC 1123, max 253 chars). **Immutable**. |
| `acme_challenge` | string | no | `null` | `http01` / `dns01` — sinon aucun cert TLS émis. **Immutable**. |
| `acme_dns_provider` | string | no | `null` | Clé provider DNS pour `dns01` (ex. `cloudflare`). **Immutable**. |
| `acme_dns_credentials` | map(string) | no | `null` | Credentials DNS pour `dns01` (sensible, write-only). **Immutable**. |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `id` | no | UUID du listener. |
| `appgw_id` | no | UUID de la gateway parente. |
| `hostname` | no | Hostname effectivement servi. |
| `acme_challenge` | no | `http01` / `dns01` / `null`. |
| `acme_status` | no | `pending` / `issued` / `failed`. |
| `acme_issued_at` | no | Timestamp RFC 3339 d'émission du cert courant. |
| `acme_renew_after` | no | Timestamp RFC 3339 d'éligibilité au renouvellement. |
| `acme_last_renewal_at` | no | Timestamp RFC 3339 du dernier renouvellement. |
| `cert_path` | no | Chemin filesystem informatif du cert live. |
| `created_at` | no | Timestamp RFC 3339 de création. |

## Notes

- **Tout est immutable** : `appgw_id`, `hostname`, `acme_challenge`, `acme_dns_provider`, `acme_dns_credentials`. Toute modification déclenche un destroy + create — donc une coupure brève sur ce hostname et l'émission d'un nouveau cert ACME (~30-90s en HTTP-01, plus long en DNS-01 selon le TTL).
- **Sans `acme_challenge`** : aucun certificat TLS n'est jamais émis pour le listener.
- **`http01`** : la gateway doit être joignable sur le port 80 pour ce hostname (CNAME / A record en place avant l'apply).
- **`dns01`** : fournir `acme_dns_provider` + `acme_dns_credentials`. Découvrir les providers DNS supportés et leurs clés via la data source `ccp_acme_dns_providers`.
- **Rate limit Let's Encrypt** : 50 certs/semaine/registered domain.
- **Pas de cert custom** : la plateforme ne supporte pas l'upload de cert externes — uniquement Let's Encrypt. Pour un cert d'entreprise CA, ouvrir un ticket support.


### Politiques d’accès (#1828)

Terraform 1.9 minimum (validation des domaines entre variables).

Les entrées `l4_policy`, `l7_policy` et `client_ip_policy` de la passerelle,
et `l7_policy` des listeners/routes, utilisent les objets typés du provider
**8.1.0 minimum** (publication requise avant livraison de ces modules).
Une valeur omise ou `null` conserve la protection distante, notamment après
import ; `{}` demande explicitement sa suppression. Les maps `policies`,
`allow_rules`, `deny_rules` et `required_headers` sont indexées par des clés
stables. `match.headers` est une liste de critères combinés par ET.

Une autorisation locale ne contourne aucun refus hérité. TCP/80 restrictif
nécessite DNS-01/certificat importé ; une politique d’en-têtes exige le cache
`off` sur les routes concernées. Les domaines avec une route regex ne peuvent
pas activer les politiques L7. Le provider vérifie la capacité de l’API et la
convergence des instances avant d’annoncer la fin de la modification.

Pour les modules `managed/application-gateway` et `exposure/web-app-with-appgw`, `listener_l7_policies` est une map indexée par
hostname, et `routes[*].l7_policy` porte les règles propres à la route.
La landing zone expose les trois politiques de passerelle avec le préfixe `appgw_` ; pour une politique propre à un listener ou une route, utiliser les modules managed/exposure.
Le filtrage hérité `allow_cidrs` / `deny_cidrs` conserve son sens HTTP.
