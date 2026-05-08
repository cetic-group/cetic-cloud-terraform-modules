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
| `tags` | list(string) | `[]` | Tags du VPC. |
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
| `vnet_ids` | map(string) | `{<key> => <uuid>}` — passe à d'autres modules. |
| `vnets` | map(object) | VNets complets (id, name, cidr, gateway, status). |
| `ip_reservations` | map(object) | `{<vnet_key>:<resv_key> => {id, ip_address}}`. |
| `peering_ids` | map(string) | `{<accepter_vpc_id> => <peering_uuid>}`. |

## Notes

- **NAT Gateway** : provisionné automatiquement à la 1ère VNet du VPC (lazy). Aucune action requise côté Terraform.
- **`isolated=true`** : sans `firewall_rules` au moins un `direction=in`, le VNet bloquera tout trafic entrant — bonne hygiène en prod, mais penser au moins à ouvrir SSH ou la santé.
- **Peering** : `peering_vpc_ids` ne supporte que le même tenant pour l'instant. Cross-tenant nécessite une approbation hors-Terraform via la console.
