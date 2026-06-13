# managed/bastion

Module Terraform pour un **bastion SSH** CETIC Cloud Platform (CCP).

Le bastion est un point d'entrée SSH unique et audité qui fronte les instances
**privées** d'un VPC (containers, VMs). Au lieu d'exposer chaque instance sur
Internet, les opérateurs s'y connectent à travers un seul endpoint public
(`endpoint_host:endpoint_port`) ; la plateforme route ensuite les connexions
vers les instances privées du VPC.

## Exemple

```hcl
module "bastion" {
  source = "./modules/managed/bastion"

  name   = "ops-bastion"
  region = "RNN"
  plan   = "small"
  vpc_id = module.vpc.vpc_id
  tags   = ["env:prod", "team:ops"]

  depends_on = [module.vpc] # bastion détruit avant le VPC (NAT GW nécessaire au teardown)
}

output "bastion_ssh" {
  value = "${module.bastion.endpoint_host}:${module.bastion.endpoint_port}"
}
```

## Rattachement VPC

Fournissez **`vpc_ids`** (liste, 1 à 5 VPC à fronter) **OU** `vpc_id` (raccourci
pour un seul). Au moins un VPC est requis, au plus 5 — deux `precondition`
échouent sinon. `vpc_ids` est prioritaire sur `vpc_id`. Le module dérive le
**VPC primaire** (`vpc_id`, requis côté provider, toujours inclus dans
l'ensemble) : `var.vpc_id` s'il est fourni, sinon le 1er de `var.vpc_ids`. Pour
un VPC unique, `vpc_ids` est laissé à la plateforme (qui le dérive de `vpc_id`).

## Inputs

| Name           | Type           | Required | Default   | Description                                                                        |
| -------------- | -------------- | :------: | --------- | ---------------------------------------------------------------------------------- |
| `name`         | `string`       |    oui   | —         | Nom du bastion (1–100 chars ; lettres, chiffres, `_`, `-`, espaces). Immutable.    |
| `region`       | `string`       |    oui   | —         | `RNN` / `PAR` / `ABJ`. Immutable.                                                  |
| `plan`         | `string`       |   non    | `"small"` | `small` / `medium` / `large`.                                                      |
| `vpc_ids`      | `list(string)` | l'un¹    | `null`    | UUID des VPC dont les instances privées sont joignables via le bastion. Immutable. |
| `vpc_id`       | `string`       | l'un¹    | `null`    | Raccourci pour un seul VPC. Ignoré si `vpc_ids` est fourni. Immutable.             |
| `public_ip_id` | `string`       |   non    | `null`    | UUID d'une IP publique à attacher comme endpoint. `null` = alloc automatique.      |
| `tags`         | `list(string)` |   non    | `[]`      | Tags free-form (max 60, max 50 chars chacun).                                      |

¹ Fournir **`vpc_ids` OU `vpc_id`** (au moins un VPC requis).

## Outputs

| Name                | Sensitive | Description                                                          |
| ------------------- | :-------: | ------------------------------------------------------------------- |
| `id`                |    non    | UUID du bastion.                                                    |
| `status`            |    non    | `provisioning` / `active` / `error` / `deleting`.                  |
| `endpoint_host`     |    non    | Hôte public du point d'entrée SSH (FQDN ou IP).                    |
| `endpoint_port`     |    non    | Port TCP du point d'entrée SSH.                                    |
| `public_ip_address` |    non    | IP publique attachée au point d'entrée.                            |
| `vpc_ids`           |    non    | Ensemble des VPC fronté(s) (le VPC primaire est toujours inclus). |

## Notes

- **Immutabilité** : `name`, `region` et le rattachement VPC forcent le
  remplacement (la plateforme n'expose aucun endpoint de mise à jour pour les
  bastions). Pour déplacer un bastion vers un autre VPC ou une autre région,
  Terraform le recrée.
- **Provisioning asynchrone** : juste après `apply`, `status` vaut
  `provisioning` et `endpoint_host` / `endpoint_port` peuvent être vides ; ils
  sont renseignés une fois l'appliance `active`. Un `terraform refresh`
  ultérieur reflète l'endpoint final.
- **Ordre de destruction** : ajoutez `depends_on = [module.vpc]` — le bastion
  doit être détruit **avant** le VPC (le teardown du NAT GW déclenché par le
  delete du VPC est nécessaire au release des ressources de l'appliance).
- **`bastion_access`** : pour ouvrir l'accès bastion à une instance précise
  (container / VM / scale-set), c'est l'argument `bastion_access` des modules
  `compute/*` qu'il faut activer — ce module-ci provisionne le bastion lui-même.
- **Parité provider** : ce module est calqué sur `managed/vpn-gateway` et expose
  `plan`, `vpc_ids` (multi-VPC 1–5), `public_ip_id` et `tags`, tous câblés sur
  `ccp_bastion` depuis le provider **v4.9.0** (parité avec `ccp_vpn_gateway`).
