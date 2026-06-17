# Example — Windows VM + Windows scale set

Provisionne une **VM Windows** et un **VM scale set Windows** dans un VPC, via
les modules `compute/vm` et `compute/vm-scale-set`. Les instances Windows sont
accédées en **RDP** (pas de SSH) ; le compte administrateur est `Administrator`.

> ⚠️ **Licence Windows** — CETIC Cloud ne fournit pas les licences Windows. Vous
> devez détenir une licence valide par instance et l'attester via
> `windows_license_consent = true` (sinon l'API renvoie une erreur 422).

## Pré-requis Windows

| Contrainte | Valeur |
|------------|--------|
| Image système | template `win-*` (ex. `win-2022`) ou template custom capturé depuis une VM Windows |
| Plan minimum | `medium` (4 vCPU / 8 Go) |
| Mot de passe administrateur | ≥ 12 caractères, ≥ 3 catégories (minuscule, majuscule, chiffre, symbole) |
| Accès | RDP (port 3389) — pas de clés SSH ni cloud-init |
| `windows_license_consent` | `true` (obligatoire) |

## Usage

```bash
export TF_VAR_ccp_api_key="ccp_live_..."
export TF_VAR_windows_admin_password='Str0ng-P@ssw0rd!'
terraform init
terraform apply
```

## Outputs

| Nom | Description |
|-----|-------------|
| `vm_os_family` | `windows` (dérivé du template) |
| `vm_ip` | IP privée de la VM Windows |
| `pool_os_family` | `windows` pour le scale set |
