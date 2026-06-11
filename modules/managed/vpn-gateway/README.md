# managed/vpn-gateway

Module Terraform pour une passerelle d'**accès VPN privé** CETIC Cloud Platform (CCP).

La passerelle expose les ressources privées d'un ou plusieurs VPC à des clients
distants via un tunnel chiffré, sans avoir à publier ces ressources sur Internet.
Vous enregistrez vos clients (« peers ») et la plateforme gère le point d'entrée
public, le routage vers vos VPC et l'allocation des adresses privées.

Deux modèles d'enrôlement des clients sont supportés :

- **Clé fournie par le client** : le client génère son couple de clés et vous ne
  transmettez que sa clé publique. Aucune clé privée ne transite par la plateforme
  ni par le state Terraform (recommandé).
- **Clé générée par la plateforme** : la plateforme génère le couple de clés et
  retourne une configuration prête à l'emploi (récupérable une seule fois, ou
  stockée dans le state si vous le demandez explicitement).

## Exemple

```hcl
module "vpn" {
  source = "./modules/managed/vpn-gateway"

  name           = "ops"
  region         = "RNN"
  plan           = "small"
  vpc_id         = module.vpc.vpc_id
  peer_pool_cidr = "10.99.0.0/24"
  dns            = ["10.10.0.2"]
  tags           = ["env:prod", "team:ops"]

  peers = {
    # Modèle « clé fournie par le client » : seule la clé publique est transmise.
    alice = {
      public_key = "abcd1234ExamplePublicKeyBase64="
    }
    # Modèle « clé générée par la plateforme » : config retournée (sensible).
    laptop-ci = {
      managed           = true
      store_private_key = true
    }
  }
}

output "vpn_endpoint" {
  value = "${module.vpn.endpoint_host}:${module.vpn.endpoint_port}"
}

output "vpn_peer_configs" {
  value     = module.vpn.peer_configs
  sensitive = true
}
```

## Inputs

| Name | Type | Required | Default | Description |
|---|---|---|---|---|
| `name` | string | yes | — | Nom (1–100 chars). |
| `region` | string | yes | — | `RNN` / `PAR` / `ABJ`. Force replacement. |
| `plan` | string | no | `small` | `small` / `medium` / `large`. |
| `vpc_ids` | list(string) | * | `null` | UUID des VPC exposés. Au moins un VPC requis (via `vpc_ids` ou `vpc_id`). |
| `vpc_id` | string | * | `null` | Raccourci pour un VPC unique. Ignoré si `vpc_ids` est fourni. |
| `public_ip_id` | string | no | `null` | IP publique à utiliser comme point d'entrée. `null` = allocation automatique. |
| `peer_pool_cidr` | string | no | `null` | CIDR privé alloué aux clients. `null` = plage par défaut hors-conflit. |
| `dns` | list(string) | no | `[]` | Serveurs DNS poussés aux clients. |
| `tags` | list(string) | no | `[]` | Free-form tags (max 60, max 50 chars chacun). |
| `peers` | map(object) | no | `{}` | Clients VPN à enregistrer (voir schéma ci-dessous). |

\* Fournir **soit** `vpc_ids` **soit** `vpc_id` (au moins un VPC, precondition).

### Schéma `peers`

Map keyed par label logique → objet :

| Champ | Type | Default | Description |
|---|---|---|---|
| `name` | string | clé de la map | Nom affiché du peer. |
| `public_key` | string | `null` | Clé publique du client (modèle « clé fournie »). |
| `managed` | bool | `false` | La plateforme génère le couple de clés (modèle « clé générée »). |
| `store_private_key` | bool | `false` | Stocke la config générée dans le state (modèle « clé générée »). |
| `one_time` | bool | `false` | Config à usage unique, invalidée après la 1ère récupération (modèle « clé générée »). |

Chaque peer doit fournir **soit** `public_key` **soit** `managed = true`, jamais
les deux ni aucun (validation).

## Outputs

| Name | Sensitive | Description |
|---|---|---|
| `gateway_id` | no | UUID de la passerelle VPN. |
| `status` | no | `creating` / `active` / `error` / `deleting`. |
| `endpoint_host` | no | Hôte public du point d'entrée (FQDN ou IP). |
| `endpoint_port` | no | Port UDP du point d'entrée. |
| `public_key` | no | Clé publique de la passerelle (à mettre dans la config client). |
| `public_ip_address` | no | IP publique du point d'entrée. |
| `peers` | no | Map `label → { id, ip }` (adresse privée assignée au client). |
| `peer_configs` | yes | Map `label → config` cliente complète (`null` pour les peers « clé fournie »). |

## Notes

- **`peer_configs`** est sensible et stocké dans le state Terraform pour les peers
  en modèle « clé générée par la plateforme ». Sécurisez votre backend state, ou
  préférez le modèle « clé fournie par le client » (`public_key`) pour qu'aucune
  clé privée ne transite jamais.
- Le `region` force le replacement de la passerelle.
- Au moins un VPC doit être rattaché. Pour exposer plusieurs VPC depuis une seule
  passerelle, utilisez `vpc_ids = [...]`.
- Le `peer_pool_cidr` ne doit pas chevaucher les CIDR de vos VPC ni de vos VNets.

## Versions

| Composant | Version |
|---|---|
| Module | `>= 0.24.0` |
| Provider `cetic-group/ccp` | `>= 4.4.0` |
| Terraform | `>= 1.7` |
