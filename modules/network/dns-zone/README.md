# Module `network/dns-zone`

Une **zone DNS privée** et ses enregistrements. La zone n'est répondue que
**dans le réseau privé du client** — elle n'est publiée nulle part sur
Internet — et les machines de ce réseau reçoivent son serveur de noms
automatiquement.

Le module enveloppe `ccp_dns_zone` et, par `for_each`, autant de
`ccp_dns_record` que nécessaire.

## Trois choses à savoir avant de s'en servir

**Le niveau de service appartient au RÉSEAU, pas à la zone.** Toutes les zones
d'un même `vpc_id` sont répondues par le même serveur de noms, donc partagent
son `tier`. Déclarer une seconde zone dans ce réseau avec un `tier` différent
est refusé, et le message nomme le niveau déjà en place.

**Les machines reçoivent le serveur de noms à leur CRÉATION.** Poser une zone
sur un réseau déjà peuplé ne la rend pas visible depuis les machines
existantes. Déclarer la zone avant les machines est l'ordre qui marche ; sinon,
il faut les recréer.

**Depuis une machine, il faut l'adresse de SON sous-réseau.** Le serveur pose
une adresse dans chacun des sous-réseaux du réseau privé. Elles répondent
toutes les mêmes zones, mais chacune n'est joignable que depuis le sien. C'est
à cela que sert la sortie `resolver_by_vnet`.

## Exemple — nom interne, le cas courant

```hcl
module "vpc" {
  source = "../../modules/network/vpc"

  name   = "corp"
  region = "RNN"

  vnets = {
    bureau  = { cidr = "10.20.0.0/24", snat = true }
    atelier = { cidr = "10.21.0.0/24", snat = true }
  }
}

module "dns" {
  source = "../../modules/network/dns-zone"

  name        = "corp.internal"
  vpc_id      = module.vpc.id
  tier        = "prod" # serveur redondant, bascule automatique
  default_ttl = 300

  records = {
    www = {
      name    = "www"
      type    = "A"
      ttl     = 300
      records = ["10.20.0.10", "10.20.0.11"]
    }
    apex_mx = {
      name    = "@"
      type    = "MX"
      records = ["10 mail.corp.internal."]
    }
    spf = {
      name    = "@"
      type    = "TXT"
      records = ["\"v=spf1 -all\""]
    }
  }
}

output "serveur_de_noms_par_sous_reseau" {
  value = module.dns.resolver_by_vnet
}
```

Un suffixe interne (`corp.internal`, `home.arpa`, `lan`, ou une étiquette
unique comme `corp`) ne demande aucune preuve de possession : la zone est
servie directement.

## Exemple — domaine public, en deux `apply`

Un **domaine public** (`exemple.com`) est retenu tant que sa possession n'est
pas prouvée. Le premier `apply` rend l'enregistrement à publier ; le second,
une fois celui-ci en ligne, active la zone.

```hcl
module "dns_public" {
  source = "../../modules/network/dns-zone"

  name   = "exemple.com"
  vpc_id = module.vpc.id

  # 1er apply : false — rend la main tout de suite avec l'enregistrement.
  # 2e apply, une fois le TXT publié : true — contrôle la preuve et attend.
  wait_for_verification = var.dns_verified
}

output "a_publier" {
  value = module.dns_public.ownership_challenge
}
```

## Ce que le module n'expose pas, et pourquoi

- **Aucune ressource « serveur de noms ».** Il n'est pas pilotable : il naît
  avec la première zone du réseau privé et est démonté avec la dernière.
  L'exposer laisserait croire qu'on peut le créer ou le supprimer seul.
- **Pas de type `NS`.** Celui de l'apex est posé par la plateforme et en
  lecture seule ; ailleurs c'est une délégation, qu'une zone privée refuse. Le
  module rejette `NS` au plan plutôt que de laisser l'API rendre un 422.

## Inputs

| Nom | Type | Défaut | Description |
|---|---|---|---|
| `name` | `string` | — | Nom de la zone, ex. `corp.internal`. |
| `vpc_id` | `string` | — | UUID du **réseau privé** servi (pas d'un sous-réseau). Neuf sous-réseaux au maximum. |
| `tier` | `string` | `null` | `dev` ou `prod`. `null` = défaut plateforme (`dev`). **Partagé par toutes les zones du réseau.** |
| `default_ttl` | `number` | `null` | 60 à 604800 s. `null` = réglage de la plateforme (3600). |
| `dnssec_enabled` | `bool` | `false` | Signe la zone. Sur une zone privée, protège de presque rien. |
| `wait_for_verification` | `bool` | `false` | Domaine public seulement : contrôle la preuve de possession et attend. |
| `records` | `map(object)` | `{}` | Enregistrements, indexés par une clé libre. Voir ci-dessous. |

`records` — chaque entrée : `name` (relatif, absolu ou `@`), `type`
(`A`/`AAAA`/`CNAME`/`MX`/`TXT`/`SRV`/`CAA`), `records` (1 à 32 valeurs, en
syntaxe de présentation), `ttl` optionnel (60 à 604800, `null` = 3600).

> **`records` REMPLACE.** Chaque `apply` envoie l'ensemble des valeurs du
> couple (nom, type) : une valeur retirée de la configuration cesse d'être
> répondue. Il n'y a pas d'ajout incrémental — c'est le modèle de l'API, et
> c'est exactement celui de Terraform.

## Outputs

| Nom | Description |
|---|---|
| `id` | UUID de la zone. |
| `name` | Nom normalisé par la plateforme. |
| `status` | `pending_verification` / `provisioning` / `active` / `error` (terminal). |
| `resolver_addresses` | Adresses du serveur de noms, **une par sous-réseau**. Vide tant qu'il n'est pas debout. |
| `resolver_endpoints` | Les mêmes, avec leur sous-réseau (`address`, `vnet_id`, `vnet_name`, `vnet_cidr`). |
| `resolver_by_vnet` | **Sous-réseau → adresse à y utiliser.** La forme à consommer. |
| `resolver_tier` | Niveau réellement en service (le niveau *demandé* tant que la zone attend sa preuve). |
| `resolver_status` | État du serveur de noms lui-même, constaté. |
| `ns_hostname` | Nom du serveur publié à l'apex. Informatif. |
| `ownership_challenge` | Domaine public en attente : l'enregistrement à publier. `null` sinon. |
| `record_ids` | Clé → UUID de l'enregistrement. |
| `record_fqdns` | Clé → nom pleinement qualifié stocké par la plateforme. |

## Tests

```bash
cd modules/network/dns-zone && terraform test
```

Six runs `tftest` en `mock_provider` : réglages laissés à la plateforme (le
module ne fige ni `tier` ni `default_ttl`), zone avec enregistrements, et
quatre refus au plan (`NS`, enregistrement sans valeur, TTL hors bornes, `tier`
inconnu).
