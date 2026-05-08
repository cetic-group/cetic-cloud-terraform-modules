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

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | string | yes | — | Bucket S3 DNS-compatible. |
| `region` | string | yes | — | `RNN`/`PAR`/`ABJ`. |
| `is_public` | bool | no | `false` | Lecture anonyme. |
| `scoped_keys` | map(object({access_level})) | no | `{}` | `read` / `write` / `readwrite` / `full`. |
| `tags` | list(string) | no | `[]` | |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `id` | no | UUID. |
| `name` | no | Nom. |
| `endpoint_url` | no | Endpoint S3. |
| `access_key` | no | Master access key. |
| `scoped_keys` | **yes** | Map de creds par label. |
