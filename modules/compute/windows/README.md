# Module `compute/windows`

Wrapper minimal autour de `ccp_windows_instance` (instances Windows via dockur). Expose les options classiques (réseau, volumes, IP publique).

## Exemple

```hcl
module "workstation" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/compute/windows?ref=v0.29.0"

  name                   = "dev-workstation"
  region                 = "RNN"
  plan                   = "medium"
  template               = "windows-11-pro"
  vnet_id                = module.vpc.vnet_ids.default
  public_ip_id           = ccp_public_ip.workstation.id
  administrator_password = "Ch@ng3M3S00N!"
  data_volume_ids        = [ccp_block_volume.data.id]
  tags                   = ["dev", "workstation"]

  # OBLIGATOIRE : consentement — CCP ne fournit pas de licence Windows
  license_consent = true
}
```

## Notes importantes

- **Licence Windows** : CETIC Cloud Platform fournit l'image Windows pré-packagée mais ne fournirait **aucune licence**. Vous acceptez en posant `license_consent = true` que vous êtes responsable de la fourniture de votre propre licence Windows (achat, activation KMS/MAK/CCM selon votre contrat Microsoft).

- **Plan minimum** : Windows requiert au minimum **`plan = "medium"`** (3 vCPU / 6 Go RAM). Les plans nano/micro/small sont rejetés.

- **Templates** : Clés ex: `windows-11-pro`, `windows-11-home`, `windows-2022-datacenter`, `windows-2019-standard` (liste complète via API CCP ou backoffice).

- **Volumes de données** : Figés au create (max 5). Modification post-create passera par une re-création.

- **Accès réseau** : l'IP privée est **dynamique** au sein du VNet. Attacher un IP publique pour la joindre depuis l'extérieur. RDP port défaut = 3389.

---

## Inputs

| Nom | Type | Requis | Défaut | Description |
|-----|------|--------|--------|-------------|
| `name` | string | ✅ | — | Nom de l'instance Windows. |
| `region` | string | ✅ | — | Région (RNN, PAR, ABJ). |
| `plan` | string | ❌ | `"medium"` | Plan instance (nano/micro/small/medium/large/xlarge). **Windows ≥ medium**. |
| `template` | string | ✅ | — | Version Windows (clé de template, ex: `windows-11-pro`). |
| `vnet_id` | string | ❌ | `null` | UUID du VNet où rattacher l'instance. |
| `public_ip_id` | string | ❌ | `null` | UUID de l'IP publique à attacher (optionnel). |
| `administrator_password` | string | ✅ | — | Mot de passe administrateur (8–128 caractères, sensible). |
| `data_volume_ids` | list(string) | ❌ | `[]` | UUIDs des volumes de données (max 5, figés au create). |
| `tags` | list(string) | ❌ | `[]` | Tags associés. |
| `license_consent` | bool | ❌ | `false` | **Obligatoire = `true`** pour confirmer acceptation licence Windows. Lève une erreur sinon. |

---

## Outputs

| Nom | Type | Sensible | Description |
|-----|------|----------|-------------|
| `id` | string | — | UUID de l'instance. |
| `hostname` | string | — | Nom d'hôte (FQDN). |
| `ip_address` | string | — | IP privée du VNet. |
| `public_ip_address` | string | — | IP publique (null si non attachée). |
| `status` | string | — | État : provisioning \| active \| stopped \| error. |
| `cores` | number | — | Nombre de vCPU selon le plan. |
| `memory_mb` | number | — | RAM (MB) selon le plan. |
| `disk_gb` | number | — | Taille disque système (GB). |
