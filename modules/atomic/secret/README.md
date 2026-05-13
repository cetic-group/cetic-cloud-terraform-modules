# Module `atomic/secret`

Wrapper minimal 1-1 autour de `ccp_secret`. Stocke un secret chiffré
(AES-256-GCM côté plateforme) dans le CETIC Cloud Secret Manager. Le
secret est **agnostique Kubernetes** : c'est un coffre-fort générique
clé/valeur. Le type natif Kubernetes (`Opaque`, `kubernetes.io/tls`, …)
est décidé sur la CRD `CCPSecret` au moment du sync vers un cluster
CCKS — pas ici.

## Exemple — Secret simple (mot de passe)

```hcl
module "db_password" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/secret?ref=v0.7.0"

  name = "prod-db-password"
  data = {
    password = var.db_password
  }
  tags = ["env:prod", "team:platform"]
}
```

## Exemple — Secret transportant des fichiers (paire TLS)

Le type K8s natif (`kubernetes.io/tls`) est spécifié côté CRD
`CCPSecret`, pas dans le module. Côté plateforme, c'est juste un blob
clé/valeur.

```hcl
module "wildcard_tls" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/secret?ref=v0.7.0"

  name        = "wildcard-cetic-tls"
  description = "Paire TLS wildcard — type fixé sur la CRD CCPSecret"
  data = {
    "tls.crt" = file("./certs/wildcard.crt")
    "tls.key" = file("./certs/wildcard.key")
  }
  tags = ["env:prod"]
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | string | yes | — | DNS-friendly nom (regex `^[a-z][a-z0-9-]{0,62}$`), unique dans l'org. |
| `data` | map(string) | yes (sensible) | — | Paires clé/valeur en clair à chiffrer. Au moins 1 entrée. |
| `description` | string | no | `null` | Description libre (max 500 chars). |
| `tags` | list(string) | no | `[]` | Tags libres pour organiser les secrets (ex. `["env:prod", "team:platform"]`). |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `id` | no | UUID du secret. |
| `name` | no | Nom DNS-friendly (à utiliser dans la CRD `CCPSecret`). |
| `version` | no | Compteur monotone — bump à chaque rotation. |
| `created_at` | no | RFC 3339 création. |
| `updated_at` | no | RFC 3339 dernière modif. |

## Notes

- **`data` est sensible** et persisté en clair dans le state Terraform. Le
  backend de state doit être chiffré au repos avec accès restreint.
- **Pas de drift detection sur `data`.** Le provider n'appelle pas
  l'endpoint reveal (audit-loggé). Pour resynchroniser après une rotation
  out-of-band : changer `data` dans la config (déclenche un rotate API)
  ou taint le module.
- **`name` est immuable.** Changer le nom force un destroy + create.
- **`description` et `tags` sont mutables in-place** (PATCH).
- Le passage de `data` à une nouvelle valeur déclenche `POST
  /v1/secrets/{id}/rotate` côté API et bump `version`.

## Consommation depuis un cluster CCKS

Une fois le secret créé, déployer une `CCPSecret` dans le namespace cible.
**Le type natif Kubernetes** (`Opaque`, `kubernetes.io/tls`, etc.) est
spécifié dans `spec.target.type` au niveau de la CRD :

```yaml
apiVersion: ccp.cloud/v1
kind: CCPSecret
metadata:
  name: wildcard-cetic-tls
  namespace: app
spec:
  secretRef:
    name: wildcard-cetic-tls
  target:
    type: kubernetes.io/tls   # ← décidé ici, pas côté Secret core
  refreshInterval: 5m
```

L'agent CCKS watche la CRD, fetch le secret via l'API CETIC, et synchronise
un `Secret` Kubernetes natif avec le `type` demandé.
