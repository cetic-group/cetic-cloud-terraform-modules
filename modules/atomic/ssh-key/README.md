# Module `atomic/ssh-key`

Wrapper minimal autour de `ccp_ssh_key`. Enregistre une clé publique OpenSSH sur CETIC Cloud Platform pour qu'elle puisse être injectée dans les containers et VMs au boot via `ssh_key_ids`.

## Exemple

```hcl
module "ops_key" {
  source     = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/ssh-key?ref=v0.1.0"
  name       = "ops-team-ed25519"
  public_key = file("~/.ssh/id_ed25519.pub")
}

# Utilisation downstream
resource "ccp_container_instance" "web" {
  # ...
  ssh_key_ids = [module.ops_key.id]
}
```

## Inputs

| Name | Type | Required | Description |
|------|------|----------|-------------|
| `name` | string | yes | Nom de la clé (1-100 chars). |
| `public_key` | string | yes | Contenu OpenSSH (`ssh-ed25519 …`, `ssh-rsa …`, `ecdsa-sha2-…`). |

## Outputs

| Name | Description |
|------|-------------|
| `id` | UUID — à passer dans `ssh_key_ids` des containers/VMs. |
| `name` | Nom de la clé. |
| `fingerprint` | SHA-256 calculé côté serveur. |

## Notes

- `public_key` est immutable. Pour rotater : créer une nouvelle clé, mettre à jour les références, supprimer l'ancienne.
- La clé privée ne quitte jamais ta machine.
