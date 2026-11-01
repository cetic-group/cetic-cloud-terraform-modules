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

Ce module exige le provider `cetic-group/ccp` **`>= 7.4.0`**. Sans `cors_rules`,
une configuration CORS posée depuis la console ou le CLI n'est pas modifiée.

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | string | yes | — | Bucket S3 DNS-compatible. |
| `region` | string | yes | — | `RNN`/`PAR`/`ABJ`. |
| `is_public` | bool | no | `false` | Lecture anonyme. |
| `scoped_keys` | map(object({access_level})) | no | `{}` | `read` / `write` / `readwrite` / `full`. |
| `cors_rules` | list(object) | no | `[]` | Règles CORS (origines, méthodes, en-têtes, durée). Vide = CORS non géré. Voir ci-dessous. |
| `tags` | list(string) | no | `[]` | |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `id` | no | UUID. |
| `name` | no | Nom. |
| `endpoint_url` | no | Endpoint S3. |
| `access_key` | no | Master access key. |
| `scoped_keys` | **yes** | Map de creds par label. |
