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
│   │   ├── ipaas-pool/
│   │   ├── iam-role/
│   │   ├── iam-role-assignment/
│   │   ├── service-account/
│   │   └── secret/
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
│       ├── k8s-cluster/      # CCKS + node pools + ingress
│       ├── registry/         # CETIC Container Registry (CCR)
│       └── iam-role/         # IAM role custom (Roles v1) avec composition statements/conditions
│
├── landing-zones/            # Compositions prêtes à l'emploi
│   ├── basic-web-app/        # VPC + LB + scale set + DB PG (3-tier)
│   ├── k8s-platform/         # VPC + CCKS + ingress + DB
│   ├── iam-team-segregation/ # Roles + SAs ségrégués dev/staging/prod (Roles v1)
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
      version = ">= 0.18.0"
    }
  }
}

provider "ccp" {
  api_url = "https://api.cloud.cetic-group.com"
  api_key = var.ccp_api_key  # `cl_live_…`
}

module "vpc" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/vpc?ref=v0.8.0"

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
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//landing-zones/basic-web-app?ref=v0.8.0"

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

### IAM Roles v1 (depuis v0.5.0)

```hcl
# Crée un rôle custom + un service account CI + l'assignment
module "registry_deployer" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/managed/iam-role?ref=v0.8.0"

  name        = "RegistryDeployer-prod"
  description = "Push autorisé sur registry/prod-* uniquement"
  statements = [
    {
      effect    = "Allow"
      actions   = ["registry:Push", "registry:Pull"]
      resources = ["arn:ccp:registry:rnn:${var.tenant_id}:registry/prod-*"]
    },
  ]
}

module "ci_prod" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/service-account?ref=v0.8.0"

  name       = "ci-prod"
  expires_at = "2027-05-12T00:00:00Z"
}

module "ci_prod_can_deploy" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/iam-role-assignment?ref=v0.8.0"

  role_id        = module.registry_deployer.role_id
  principal_type = "service_account"
  principal_id   = module.ci_prod.id
}

output "ci_prod_token" {
  value     = module.ci_prod.token   # ccp_sa_*** — affiché une seule fois
  sensitive = true
}
```

Ou utilise la landing-zone **`iam-team-segregation`** qui compose ce pattern × 3 environnements (dev / staging / prod) + un rôle transverse `BillingViewer`.

## Versionnage

Suit le provider `cetic-group/cetic-cloud-platform`. Tag SemVer :
- `v0.1.x` : compatible provider `>= 0.5.0`
- `v0.4.x` : compatible provider `>= 0.10.0`
- `v0.5.x` : compatible provider `>= 0.11.0` — ajoute les modules IAM (Roles v1) + landing-zone `iam-team-segregation`
- `v0.6.x` : compatible provider `>= 0.12.0` — `root_password` désormais obligatoire sur `compute/vm`, `compute/container`, `compute/vm-scale-set`, `compute/container-scale-set` (breaking)
- `v0.7.x` : compatible provider `>= 0.13.0` — ajoute `atomic/secret` (Secret Manager v1) avec rotation server-side + projection K8s via CRD `CCPSecret`
- `v0.8.x` : compatible provider `>= 0.14.0` — ajoute les modules Application Gateway v1 (`atomic/application-gateway`, `atomic/appgw-route`, `atomic/appgw-target-group`, `exposure/web-app-with-appgw`) et l'option `exposure_type = "appgw"` dans la landing-zone `basic-web-app`
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
