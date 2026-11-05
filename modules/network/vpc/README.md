# Module `network/vpc`

Provisionne un VPC complet avec ses VNets, IP reservations, règles firewall et peerings inter-VPC, le tout en un seul module composable.

Particulièrement utile pour décrire la topologie réseau d'un environnement (prod, staging) en une déclaration unique, plutôt que d'enchaîner des `ccp_vnet`, `ccp_vnet_ip_reservation`, `ccp_vnet_firewall_rule` à la main.

## Exemple

```hcl
module "vpc" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/vpc?ref=v0.1.0"

  name   = "production"
  region = "RNN"
  tags   = ["env:prod", "team:platform"]

  vnets = {
    web = {
      cidr     = "10.0.1.0/24"
      snat     = true
      isolated = true
      tags     = ["web", "env:prod"]

      firewall_rules = [
        { direction = "in", protocol = "tcp", source_cidr = "0.0.0.0/0", port = "80",  description = "HTTP public" },
        { direction = "in", protocol = "tcp", source_cidr = "0.0.0.0/0", port = "443", description = "HTTPS public" },
        { direction = "in", protocol = "tcp", source_cidr = "10.0.99.0/24", port = "22", description = "SSH ops only" },
      ]
    }

    data = {
      cidr     = "10.0.2.0/24"
      snat     = true
      isolated = true
      tags     = ["data", "env:prod"]

      ip_reservations = {
        pg_primary = { ip_address = "10.0.2.10", description = "PostgreSQL primary endpoint" }
        valkey     = { ip_address = "10.0.2.11", description = "Valkey master" }
      }
    }
  }
}

# Utiliser les outputs pour piper vers d'autres modules
output "web_vnet_id" {
  value = module.vpc.vnet_ids.web
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | string | — | Nom du VPC. |
| `region` | string | — | `RNN`, `PAR` ou `ABJ`. |
| `cidr` | string | `null` | Bloc d'adressage privé du VPC (RFC1918, /16 à /24). Auto-alloué si `null`. Les `vnets[*].cidr` doivent en être des sous-réseaux. Immutable. |
| `tags` | list(string) | `[]` | Tags du VPC. |
| `dedicated_egress_ip` | bool | `false` | IP publique de sortie dédiée au VPC. `false` : sortie partagée, port TCP 25 sortant bloqué. Modifiable en place ; repasser à `false` rend l'IP au pool immédiatement. Voir ci-dessous. |
| `vnets` | map(object) | `{}` | Map de VNets (clé = nom logique). Voir le schema ci-dessous. |
| `peering_vpc_ids` | list(string) | `[]` | IDs de VPCs avec qui établir un peering (même région). |

### Schema `vnets[*]`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `cidr` | string | required | Bloc CIDR (`10.0.1.0/24`). Immutable. |
| `name` | string | clé de la map | Nom affiché. |
| `snat` | bool | `true` | Active SNAT/MASQUERADE outbound. |
| `isolated` | bool | `false` | Active l'isolation L3 + firewall DROP par défaut. |
| `tags` | list(string) | `[]` | Tags du VNet. |
| `ip_reservations` | map(object) | `{}` | Réservations d'IPs fixes (clé = label). |
| `firewall_rules` | list(object) | `[]` | Règles ACCEPT (le `position` est auto à 10, 20, 30, … dans l'ordre). |

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `vpc_id` | string | UUID du VPC. |
| `vpc` | object | VPC complet (id, name, region, status, tags). |
| `dedicated_egress_ip` | bool | Option IP de sortie dédiée active. |
| `egress_ip` | string | IP de sortie dédiée (`null` sans l'option). |
| `egress_ip_type` | string | Type de l'IP de sortie dédiée (`null` sans l'option). |
| `egress_ip_status` | string | État de l'IP de sortie dédiée (`null` sans l'option). |
| `vnet_ids` | map(string) | `{<key> => <uuid>}` — passe à d'autres modules. |
| `vnets` | map(object) | VNets complets (id, name, cidr, gateway, status). |
| `ip_reservations` | map(object) | `{<vnet_key>:<resv_key> => {id, ip_address}}`. |
| `peering_ids` | map(string) | `{<accepter_vpc_id> => <peering_uuid>}`. |

## IP de sortie dédiée

```hcl
module "vpc" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/vpc?ref=vX.Y.Z"

  name                = "acme-prod"
  region              = "RNN"
  dedicated_egress_ip = true
}

output "ip_sortie" {
  value = module.vpc.egress_ip
}
```

Sans l'option, le VPC sort par l'IP partagée de la plateforme et le port TCP 25
sortant est bloqué. Avec `dedicated_egress_ip = true`, la plateforme attribue
au VPC sa propre IP publique de sortie pendant l'apply ; elle est facturée
comme une IP publique et ne compte pas dans `max_public_ips`. L'option se
modifie en place (pas de recréation du VPC).

> ⚠️ Repasser à `false` (ou retirer l'option) rend l'IP au pool immédiatement,
> sans délai de grâce : elle peut être attribuée à un autre client, et une
> réactivation donne une IP différente. Exige le provider `cetic-group/ccp`
> **`>= 7.3.2`** et une plateforme qui propose l'option (sinon HTTP 422).

## Notes

- **NAT Gateway** : provisionné automatiquement à la 1ère VNet du VPC (lazy). Aucune action requise côté Terraform.
- **`isolated=true`** : sans `firewall_rules` au moins un `direction=in`, le VNet bloquera tout trafic entrant — bonne hygiène en prod, mais penser au moins à ouvrir SSH ou la santé.
- **Peering** : `peering_vpc_ids` ne supporte que le même tenant pour l'instant. Cross-tenant nécessite une approbation hors-Terraform via la console.
