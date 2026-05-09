# Landing zone `vpc-design`

Découpage réseau multi-VPC pour une organisation multi-environnement. Pas de compute — uniquement le socle réseau (VPCs, VNets, peerings, isolation).

```mermaid
flowchart LR
    subgraph prod0 [vpc-prod-10-0]
      p0w[web 10.0.1/24<br/>sortie internet]
      p0d[data 10.0.2/24<br/>isolated]
    end
    subgraph prod1 [vpc-prod-10-1]
      p1w[web 10.1.1/24]
      p1d[data 10.1.2/24]
    end
    subgraph stg [vpc-staging-10-2]
      sw[web 10.2.1/24]
      sd[data 10.2.2/24]
    end
    subgraph dev [vpc-dev-10-3]
      dw[web 10.3.1/24]
      dd[data 10.3.2/24]
    end

    p0w -- "in 80/443/5432" --> p0d
    p1w -- "in 5432 (via peering)" --> p0d
    p0w <-. peering inter-VPC .-> p1w

    classDef iso fill:#fef3c7,stroke:#f59e0b,color:#78350f
    class p0d iso
```

> Flèches pleines = règles firewall ACCEPT (in) sur le VNet `data` isolé. Flèche pointillée = peering L3 inter-VPC.

## Composants

- **4 VPCs** (`prod-10-0/1`, `staging-10-2`, `dev-10-3`) via `modules/network/vpc`, CIDRs `10.<env>.0.0/16` non chevauchants
- **8 VNets** (un `web` + un `data` par VPC)
- **1 peering inter-VPC** entre `prod-10-0/web` et `prod-10-1/web` via `modules/network/vnet-peering`
- **VNet `data` de prod-10-0 isolé** (`isolated = true`) avec règles firewall ACCEPT explicites : HTTP/HTTPS/PG depuis `web` local + PG depuis le peer prod-10-1/web

## Conventions choisies ici

- 1 octet par environnement dans le second octet du CIDR : `10.<env>.<vnet>.0/24`
- VNet `web` SNAT activé (sortie internet), VNet `data` SNAT off (privé)
- Isolation L3 + firewall ACCEPT seulement sur les VNets sensibles (data en prod)
- Peering déclaré côté prod-10-0 uniquement (les peerings sont symétriques, on déclare une fois)

## Usage

```bash
export CCP_API_KEY="ccp_live_..."
terraform init
terraform apply
```

La topologie est entièrement pilotée par `var.vpc_map` dans `vars.auto.tfvars` — modifier la map suffit pour ajouter un VPC ou un VNet.
