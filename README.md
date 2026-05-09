# cetic-cloud-terraform-modules

Modules Terraform officiels pour orchestrer **[CETIC Cloud Platform](https://cloud.cetic-group.com)** — du module atomique 1-1 avec le provider jusqu'aux landing zones complètes prêtes à l'emploi.

[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Terraform >= 1.7](https://img.shields.io/badge/Terraform-%E2%89%A5%201.7-purple.svg)](https://www.terraform.io)
[![Provider](https://img.shields.io/badge/provider-cetic--group%2Fcetic--cloud--platform-orange.svg)](https://registry.terraform.io/providers/cetic-group/cetic-cloud-platform/latest)

> **Repo officiel** : https://github.com/cetic-group/cetic-cloud-terraform-modules
> **Support** : ouvrez une issue ou contactez-nous sur https://console.cloud.cetic-group.com

---

## Architecture (landing zone)

```
.
├── modules/                  # Modules réutilisables, faible couplage
│   ├── atomic/               # 1-1 avec le provider — primitives
│   │   ├── ssh-key/
│   │   ├── api-key/
│   │   ├── org-member/
│   │   ├── custom-template/
│   │   └── ipaas-pool/
│   ├── network/              # VPC, peering, IP publique
│   │   ├── vpc/              # VPC + VNets + IP reservations + firewall rules
│   │   ├── vpc-peering/
│   │   └── public-ip/
│   ├── compute/              # Containers, VMs, scale sets
│   │   ├── container/
│   │   ├── container-scale-set/
│   │   ├── vm/
│   │   └── vm-scale-set/
│   ├── storage/              # Block + object storage
│   │   ├── block-volume/
│   │   └── bucket/
│   ├── exposure/             # Load balancing
│   │   └── load-balancer/    # Multi-listener, backends explicites ou par tag
│   └── managed/              # Services managés CETIC Cloud
│       ├── database/         # Sous-modules pg / valkey / mysql / ferretdb
│       └── k8s-cluster/      # CCKS + node pools + ingress
│
├── landing-zones/            # Compositions prêtes à l'emploi
│   ├── basic-web-app/        # VPC + LB + scale set + DB PG (3-tier)
│   ├── k8s-platform/         # VPC + CCKS + ingress + DB
│   └── multi-region-ha/      # 3 régions + LB cross-region
│
├── examples/                 # Recettes d'utilisation simples
│   ├── quickstart-container/
│   ├── web-3tier/
│   └── k8s-with-database/
│
└── tests/                    # Tests `terraform test` natifs (HCL)
```

## Quick start

```hcl
terraform {
  required_version = ">= 1.7"
  required_providers {
    ccp = {
      source  = "cetic-group/cetic-cloud-platform"
      version = ">= 0.9.2"
    }
  }
}

provider "ccp" {
  api_url = "https://api.cloud.cetic-group.com"
  api_key = var.ccp_api_key  # `cl_live_…`
}

module "vpc" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/vpc?ref=v0.2.0"

  name   = "production"
  region = "RNN"

  vnets = {
    web  = { cidr = "10.0.1.0/24", snat = true, tags = ["web"] }
    data = { cidr = "10.0.2.0/24", snat = true, tags = ["data"] }
  }
}
```

Ou plus simple : `landing-zones/basic-web-app` qui compose tout :

```hcl
module "web_app" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//landing-zones/basic-web-app?ref=v0.2.0"

  org_prefix    = "acme"
  region        = "RNN"
  ssh_key_path  = "~/.ssh/id_ed25519.pub"
  app_replicas  = 3
  app_image_url = "https://acme.example.com/app.tar.gz"
}

output "url" {
  value = module.web_app.public_url
}
```

## Versionnage

Suit le provider `cetic-group/cetic-cloud-platform`. Tag SemVer :
- `v0.1.x` : compatible provider `>= 0.5.0`
- bump majeur (`v1.0.0`) quand le provider stabilise son API

## Tests

```bash
make fmt          # terraform fmt -recursive
make validate     # terraform init + validate sur tous les modules
make lint         # tflint sur tous les modules
make test         # terraform test natif (plan-only, pas d'apply)
```

## Contributions

PRs bienvenues. Conventions :
- 1 module = 1 dossier avec `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`, `README.md`, optionnellement `tests/`
- Variables typées strictement (`object({ … })`, pas de `any`)
- Outputs riches (au moins l'`id`, plus tout attribut utile cross-module)
- README généré par `terraform-docs` (Makefile target `make docs`)

## Licence

Apache 2.0 — voir [LICENSE](LICENSE).
