# Module `storage/bucket`

Crée un bucket S3 (`ccp_object_bucket`) + optionnellement N clés scopées (`ccp_object_storage_key`) en une seule déclaration. Les clés sont **tenant-wide** (v1 du provider) mais avec un access_level configurable.

## Exemple

```hcl
module "assets" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/storage/bucket?ref=v0.1.0"

  name      = "acme-public-assets"
  region    = "RNN"
  is_public = true
  tags      = ["public", "cdn"]

  scoped_keys = {
    ci_upload = { access_level = "write" }
    cdn_read  = { access_level = "read" }
    backup    = { access_level = "readwrite" }
  }
}

output "ci_creds" {
  value     = module.assets.scoped_keys["ci_upload"]
  sensitive = true
}
```

## CORS

Pour qu'une page web envoie ou lise des fichiers directement depuis le bucket :

```hcl
module "uploads" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/storage/bucket?ref=vX.Y.Z"

  name   = "acme-user-uploads"
  region = "RNN"

  cors_rules = [
    {
      allowed_origins = ["https://app.example.com"]
      allowed_methods = ["PUT", "POST"]
      allowed_headers = ["Content-Type"]
      expose_headers  = ["ETag"]
    },
  ]
}
```

Ce module exige le provider `cetic-group/ccp` **`>= 7.5.0`**. Sans `cors_rules`,
une configuration CORS posée depuis la console ou le CLI n'est pas modifiée.

## Versionnage

Chaque écrasement ou suppression garde la version précédente de l'objet, effacée
après `noncurrent_version_expiration_days` jours :

```hcl
module "documents" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/storage/bucket?ref=vX.Y.Z"

  name   = "acme-documents"
  region = "RNN"

  versioning = {
    status                             = "Enabled"   # ou "Suspended"
    noncurrent_version_expiration_days = 90          # optionnel, 1 à 3650
  }
}
```

- **Sans `versioning`** (défaut `null`), le versionnage n'est pas géré : un
  réglage posé depuis la console ou le CLI n'est pas modifié.
- **On ne désactive jamais, on suspend** : S3 ne revient pas à « jamais
  versionné ». Repasser à `null` arrête la gestion, le bucket garde son
  versionnage ; pour ne plus créer de versions, mettre `status = "Suspended"`.
- **La durée n'est envoyée que si elle est renseignée.** Sans elle, changer
  `status` garde la durée en place (30 jours pour un bucket jamais
  versionné), même avec un plan sauvegardé.
- **Prendre en charge un versionnage posé hors plateforme efface des
  versions.** Sur un bucket versionné avec un client S3, les versions
  anciennes sont souvent gardées sans limite. Le premier apply pose la durée
  renseignée, 30 jours par défaut, et efface les versions plus anciennes ; le
  plan l'annonce par un avertissement. Renseignez une durée assez longue pour
  les garder.
- **Raccourcir la durée efface plus tôt les versions anciennes** : le plan
  l'annonce par un avertissement. Les versions anciennes occupent de la place
  jusqu'à leur expiration.

Le versionnage exige le provider `cetic-group/ccp` **`>= 7.5.0`**.

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | string | yes | — | Bucket S3 DNS-compatible. |
| `region` | string | yes | — | `RNN`/`PAR`/`ABJ`. |
| `is_public` | bool | no | `false` | Lecture anonyme. |
| `scoped_keys` | map(object({access_level})) | no | `{}` | `read` / `write` / `readwrite` / `full`. |
| `cors_rules` | list(object) | no | `[]` | Règles CORS (origines, méthodes, en-têtes, durée). Vide = CORS non géré. Voir ci-dessous. |
| `versioning` | object({status, noncurrent_version_expiration_days}) | no | `null` | Versionnage (`Enabled` / `Suspended`, durée 1–3650 j). `null` = non géré. Voir ci-dessus. |
| `tags` | list(string) | no | `[]` | |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `id` | no | UUID. |
| `name` | no | Nom. |
| `endpoint_url` | no | Endpoint S3. |
| `versioning` | no | Versionnage géré (`status`, `noncurrent_version_expiration_days`), ou `null`. |
| `access_key` | no | Master access key. |
| `scoped_keys` | **yes** | Map de creds par label. |
