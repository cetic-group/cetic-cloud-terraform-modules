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

Ce module exige le provider `cetic-group/ccp` **`>= 7.6.0`**. Sans `cors_rules`,
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

Le versionnage exige le provider `cetic-group/ccp` **`>= 7.5.0`** (ce module : `>= 7.6.0`).

## Client-supplied key (`encryption_mode`)

By default (`encryption_mode = null`, attribute omitted) the existing mode is kept: a new bucket has no customer-supplied key (`none`), and an imported bucket keeps its real mode. The bucket has no customer-supplied key.
With `sse_c`, **you** supply the encryption key on every read and write
request:

```hcl
module "vault" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/storage/bucket?ref=vX.Y.Z"

  name            = "acme-confidential"
  region          = "RNN"
  encryption_mode = "sse_c"
}
```

- **CETIC never knows your key and cannot recover it.** If you lose it, the
  files are lost for good. Keep it in your own secret store.
- **The mode is chosen at creation and cannot be changed.** Changing
  `encryption_mode` replaces the bucket and **deletes all its files**: copy
  them first.
- **Such a bucket is always private.** With `sse_c`, `is_public = true` is
  refused at plan time. The rule is applied to `sse_c` only, because the module
  does not know which other modes (if any) need a client key; the API validates
  the accepted values.
- The format is checked locally (lowercase letters, digits, underscores,
  starting with a letter); the list of accepted modes is validated by the API.

Requires the provider release that adds `encryption_mode` (assumed
`cetic-group/ccp` **`>= 7.6.0`**).

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | string | yes | — | Bucket S3 DNS-compatible. |
| `region` | string | yes | — | `RNN`/`PAR`/`ABJ`. |
| `is_public` | bool | no | `false` | Lecture anonyme. |
| `scoped_keys` | map(object({access_level})) | no | `{}` | `read` / `write` / `readwrite` / `full`. |
| `cors_rules` | list(object) | no | `[]` | Règles CORS (origines, méthodes, en-têtes, durée). Vide = CORS non géré. Voir ci-dessous. |
| `versioning` | object({status, noncurrent_version_expiration_days}) | no | `null` | Versionnage (`Enabled` / `Suspended`, durée 1–3650 j). `null` = non géré. Voir ci-dessus. |
| `encryption_mode` | string | no | `null` | `none` or `sse_c` (key supplied by you; private bucket only). `null` keeps the existing mode (`none` on creation). Fixed at creation; changing it replaces the bucket and deletes its files. See above. |
| `tags` | list(string) | no | `[]` | |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `id` | no | UUID. |
| `name` | no | Nom. |
| `endpoint_url` | no | Endpoint S3. |
| `encryption_mode` | no | Encryption mode of the bucket. |
| `versioning` | no | Versionnage géré (`status`, `noncurrent_version_expiration_days`), ou `null`. |
| `access_key` | no | Master access key. |
| `scoped_keys` | **yes** | Map de creds par label. |
