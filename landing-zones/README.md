# Landing zones

Stacks Terraform clé en main qui composent les modules en architectures complètes et opinionées. Chaque dossier est utilisable tel quel ou comme point de départ à forker.

| Zone | Pour quoi |
|------|-----------|
| [`basic-web-app`](basic-web-app/) | App web 3-tier (LB → containers → DB) sur 1 VPC. |
| [`k8s-platform`](k8s-platform/) | Cluster K8s managé + node pools + ingress + DB optionnelle. |
| [`vpc-design`](vpc-design/) | Layout multi-VPC (prod/staging/dev) avec peering inter-VPC et VNet isolé. |

---

## `basic-web-app` — application web publique

```mermaid
flowchart LR
    net((Internet)) --> pip[Public IP] --> lb[Load balancer] --> cs[Container scale set] --> db[(PostgreSQL)]

    subgraph web [VNet web]
      lb
      cs
    end
    subgraph data [VNet data · isolated]
      db
    end

    classDef vnet fill:#f5f7fa,stroke:#94a3b8,stroke-dasharray:4 4,color:#334155
    class web,data vnet
```

1 VPC, 2 VNets (`web` 10.0.1/24, `data` 10.0.2/24), 1 LB, N containers, 1 PG managé optionnel. Voir [`basic-web-app/`](basic-web-app/).

---

## `k8s-platform` — Kubernetes managé prêt à l'emploi

```mermaid
flowchart TD
    net((Internet)) -.-> api[Apiserver public IP] -.-> cp[Control plane HA]
    cp --> pools[Worker pools<br/>autoscaling]
    pools --> ing[Ingress controller<br/>Cilium L2]
    pools -. accède .-> db[(PostgreSQL<br/>optionnel)]

    subgraph workers [VNet workers · 10.20.1/24]
      pools
      ing
    end
    subgraph datavn [VNet data · 10.20.2/24]
      db
    end

    classDef vnet fill:#f5f7fa,stroke:#94a3b8,stroke-dasharray:4 4,color:#334155
    class workers,datavn vnet
```

Cluster avec pool initial + N pools additionnels, ingress incluster, DB optionnelle. Voir [`k8s-platform/`](k8s-platform/).

---

## `vpc-design` — fleet multi-VPC

```mermaid
flowchart LR
    subgraph prod0 [vpc-prod-10-0]
      p0w[web 10.0.1/24]
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

    p0w -- "FW in" --> p0d
    p1w -- "FW in (peering)" --> p0d
    p0w <-. peering .-> p1w

    classDef iso fill:#fef3c7,stroke:#f59e0b,color:#78350f
    class p0d iso
```

Découpage réseau pour une organisation multi-environnement : CIDRs non chevauchants, un VNet `data` isolé en prod avec règles firewall, peering L3 entre deux `web` de prod. Pas de compute — c'est le socle réseau. Voir [`vpc-design/`](vpc-design/).
