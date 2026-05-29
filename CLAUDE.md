# cetic-cloud-terraform-modules — CLAUDE.md

> Modules Terraform officiels pour CETIC Cloud Platform.
> Repo public : https://github.com/cetic-group/cetic-cloud-terraform-modules
> Provider consommé : `cetic-group/cetic-cloud-platform` (cf. `terraform-provider-cetic-cloud-platform/CLAUDE.md` pour la convention release).

---

## Convention bump version provider

À **chaque release** du provider Terraform `cetic-group/cetic-cloud-platform`
(nouveau tag `vX.Y.Z`), mettre à jour systématiquement :

1. **`versions.tf` de chaque module / landing-zone / example** :
   ```hcl
   required_providers {
     cetic-cloud-platform = {
       source  = "cetic-group/cetic-cloud-platform"
       version = ">= X.Y.Z"
     }
   }
   ```
   Une commande pour bump tout :
   ```bash
   sed -i 's|version = ">= 0.10.0"|version = ">= 0.10.0"|g' \
     $(grep -rl "0.7.1" --include="*.tf" --include="*.md" .)
   ```

2. **`README.md` racine** — la version dans le snippet Quick Start.

3. Pour les **modules qui utilisent une nouvelle resource/datasource** introduite
   dans la release, ajouter le champ correspondant aux `variables.tf` + `main.tf`
   + `outputs.tf` + tests, puis bump le tag du repo modules en SemVer minor.

4. **Tests `terraform test`** : relancer après bump pour vérifier que les
   `mock_provider` blocks fonctionnent toujours (les attributs Computed
   nouvellement ajoutés peuvent demander un mock value).

### Workflow git

```bash
# 1. Une fois le provider tagué v0.8.0 (et publié sur Registry, ~5 min après tag)
git checkout -b chore/bump-provider-v0.8.0
sed -i 's|version = ">= 0.10.0"|version = ">= 0.10.0"|g' $(grep -rl "0.7.1" --include="*.tf" --include="*.md" .)

# 2. Ajouter aux modules les nouveaux champs / datasources si pertinent
# (ssh_key_ids dans container-scale-set, datasource ccp_db_pg_credentials
#  dans managed/database/pg, etc.)

# 3. Validate + test
make fmt && make validate && make test

# 4. Commit + PR + merge + tag SemVer
git commit -am "chore: bump provider constraint to >= 0.8.0 + new module fields"
git push -u origin chore/bump-provider-v0.8.0
gh pr create --title "chore: bump provider to v0.8.0" --body "..."
gh pr merge --squash --delete-branch
git tag -a v0.2.0 -m "v0.2.0 — provider 0.8.0 + scale-set ssh_key_ids + db credentials datasource"
git push origin v0.2.0
```

---

## Architecture

```
modules/
├── atomic/                # 1-1 avec le provider — primitives
│   ├── ssh-key/
│   ├── api-key/
│   ├── org-member/
│   ├── custom-template/
│   └── ipaas-pool/
├── network/
│   ├── vpc/               # VPC + VNets + IP reservations + firewall rules + peerings
│   ├── public-ip/
│   └── vpc-peering/
├── compute/
│   ├── container/
│   ├── container-scale-set/
│   ├── vm/
│   └── vm-scale-set/
├── storage/
│   ├── block-volume/
│   └── bucket/             # bucket + scoped keys
├── exposure/
│   └── load-balancer/
└── managed/
    ├── database/           # sous-modules pg / valkey / mysql / ferretdb
    └── k8s-cluster/

landing-zones/              # compositions org-ready
├── basic-web-app/          # 3-tier : VPC + LB + N containers + DB PG
├── k8s-platform/           # VPC + CCKS + ingress + DB
└── multi-region-ha/        # 3 régions + LB cross-region

examples/                   # usage simples (≤ 30 lignes)
├── quickstart-container/
├── web-3tier/
└── k8s-with-database/
```

---

## Notes plateforme — abstractions invisibles côté Terraform

Quelques détails d'infrastructure que la plateforme gère automatiquement et qui n'ont **pas** à être pilotés depuis les modules :

- **NAT Gateway** : provisionné automatiquement à la 1ère VNet du VPC (lazy). Aucune action requise côté Terraform.

Toute notation d'infra sous-jacente (HAProxy, VRRP, CNPG, LXC, MASQUERADE, etc.) doit rester hors des descriptions/docs des modules — les consumers n'ont pas à connaître l'implémentation. Cilium peut rester quand le ingress controller K8s est documenté (le client le sait, c'est exposé via `ingress_controller_class`).

## Pièges API connus

- **`ccp_vnet_firewall_rule.direction`** : le backend valide `^(in|out|forward)$` (**lowercase**). Si tu wrappes ce champ dans un module, normalise avec `lower(...)`, **jamais** `upper(...)`. Le `action` reste uppercase (`^(ACCEPT|DROP|REJECT)$`).
- **`ccp_block_volume.attached_to_type` = `"vm"`, PAS `"vm_instance"`** (depuis provider v0.24+). **CORRIGÉ v0.18.1** : `modules/storage/block-volume` accepte désormais `container`/`vm` et mappe l'alias legacy `vm_instance` → `vm` (local `attached_to_type` dans `main.tf`). Rétro-compatible (le HCL existant en `vm_instance` continue de marcher). Tests `tests/attach_type.tftest.hcl`. Voir mémoire `feedback-tf-block-volume-attached-to-type-mismatch`.

## Pattern v1.0+ — `cetic-cloud-platform` local name + `provider = ...` explicite

Depuis v0.17.0 des modules + v1.0.0 du provider, tous les modules déclarent
le provider avec le local name `cetic-cloud-platform` (matche le snippet
"Use Provider" du Registry) :

```hcl
# versions.tf de chaque module
terraform {
  required_version = ">= 1.7"
  required_providers {
    cetic-cloud-platform = {
      source  = "cetic-group/cetic-cloud-platform"
      version = ">= 2.0.0"
    }
  }
}
```

Comme le local name (`cetic-cloud-platform`) diffère du préfixe des resource
types (`ccp_*`), Terraform ne fait **plus** l'auto-résolution. Chaque
`resource "ccp_*"` / `data "ccp_*"` dans les modules DOIT carry un
`provider = cetic-cloud-platform` explicite :

```hcl
resource "ccp_vpc" "this" {
  provider = cetic-cloud-platform   # ← OBLIGATOIRE depuis v0.17.0
  name     = var.name
  ...
}
```

**Toute nouvelle resource/data dans un module doit suivre ce pattern.**
Vérification post-edit :

```bash
grep -rL 'provider = cetic-cloud-platform' \
  $(grep -rl 'resource "ccp_\|data "ccp_' modules/ landing-zones/ examples/ --include="*.tf")
```

Côté consommateur (root module), c'est OK d'utiliser soit `cetic-cloud-platform`
(no `providers = {...}` map nécessaire) soit `ccp` (avec `providers = { cetic-cloud-platform = ccp }`
sur chaque module call). Recommander le premier dans les README.

## Ordre de destruction — depends_on explicites

L'ordre des destroys CCP est piégé par plusieurs garde-fous backend :

1. **VM/Container DELETE** refuse 409 si un volume bloc est attaché (politique v1.3.0 "détache d'abord")
2. **VNet DELETE** refuse si une VM/CCKS référence encore la VNet
3. **VPC DELETE** déclenche le teardown NAT GW — nécessaire au teardown des LXC proxies CCKS et au release des IPs IPaaS

Les références implicites Terraform suffisent en théorie, mais le
parallélisme + les poll asynchrones côté provider causent des races. Donc
**dans les exemples + landing-zones, ajouter `depends_on` explicite** :

```hcl
resource "ccp_public_ip" "vm" {
  region     = var.region
  depends_on = [module.vpc]   # release IP IPaaS → NAT GW vivant
}

module "vm" {
  source     = ".../compute/vm?ref=v0.17.0"
  ...
  depends_on = [module.vpc, module.ssh_key, ccp_public_ip.vm]
}

module "ccks" {
  source     = ".../managed/k8s-cluster?ref=v0.17.0"
  ...
  depends_on = [module.vpc]   # CCKS détruit avant VPC (NAT GW nécessaire)
}

resource "ccp_block_volume" "data" {
  attached_to_id   = module.vm.id
  attached_to_type = "vm"
  ...
  depends_on       = [module.vm]   # volume détach + delete AVANT VM
}
```

Voir mémoire `feedback-tf-destroy-order-explicit-depends-on`.

---

## Conventions par module

### Layout standard d'un module

```
<module>/
├── versions.tf       # required_version + required_providers
├── variables.tf      # tous typés, tous avec validation si pertinent
├── main.tf           # 1 ressource principale ou composition
├── outputs.tf        # id + tous attributs cross-module utiles
├── README.md         # exemple + tableaux Inputs/Outputs
└── tests/            # optionnel — *.tftest.hcl avec mock_provider
    └── <module>.tftest.hcl
```

### Variables

- **Strictement typées** : `object({ … })` plutôt que `any`. Les sub-fields utilisent `optional(...)` du HCL 1.3+.
- **Validation** systématique pour :
  - Régions (`contains(["RNN", "PAR", "ABJ"], …)`)
  - Plans (`contains(["nano", "micro", "small", …], …)`)
  - CIDR (`can(cidrhost(v, 0))`)
  - Plages numériques (`x >= min && x <= max`)
- Variables sensibles : `sensitive = true` (passwords, tokens, clés privées).

### Outputs

- Toujours exposer `id` (UUID).
- Exposer tous les attributs Computed du provider qui peuvent servir downstream :
  - Pour un container : `ip_address`, `public_ip_address`, `cores`, `memory_mb`, `disk_gb`.
  - Pour un VPC : `vnet_ids` (map keyed par nom logique) pour piper vers d'autres modules.
- Output sensitive : marquer `sensitive = true` (ne JAMAIS commit en clair).

### Tests

Utiliser **`terraform test` natif** (HCL `.tftest.hcl`) avec `mock_provider`.
Pas d'`apply` réel — la CI tourne sans creds CCP.

```hcl
mock_provider "cetic-cloud-platform" {
  mock_resource "ccp_vpc" {
    defaults = {
      id     = "00000000-0000-0000-0000-000000000001"
      status = "active"
    }
  }
}

run "creates_vpc" {
  command = plan
  variables {
    name   = "test"
    region = "RNN"
  }
  assert {
    condition     = ccp_vpc.this.name == "test"
    error_message = "Le nom du VPC doit refléter l'input."
  }
}
```

Tester aussi les cas d'échec (`expect_failures = [var.region]` quand un input
est invalide).

### Documentation

- README par module avec :
  - 1 exemple HCL en haut (copy-paste-ready)
  - Tableau Inputs (Name, Type, Required, Default, Description)
  - Tableau Outputs (Name, Sensitive, Description)
  - Section "Notes" pour les pièges (immutabilité, dépendances cross-module, etc.)
- Pas de génération auto via `terraform-docs` — conserver la flexibilité éditoriale.

---

## CI / Make targets

- `make fmt` / `make fmt-check` : format
- `make validate` : init + validate sur tous les modules
- `make lint` : tflint
- `make test` : `terraform test` natif sur tous les modules ayant un dossier `tests/`
- `make ci` : enchaîne tous les checks (le pipeline GitHub Actions appelle ce target)

CI workflow : `.github/workflows/ci.yml` (4 jobs : fmt, validate, lint, test).

---

## Dev local — `dev_overrides`

Pour développer sur le provider en parallèle, configurer un override dans
`~/.terraformrc` :

```hcl
provider_installation {
  dev_overrides {
    "cetic-group/cetic-cloud-platform" = "/home/coul/Documents/techledger/cetic-group/terraform-provider-cetic-cloud-platform"
  }
  direct {}
}
```

Et compiler le binaire avant chaque test :
```bash
cd /home/coul/Documents/techledger/cetic-group/terraform-provider-cetic-cloud-platform
go build -o ./terraform-provider-cetic-cloud-platform .
```

Avec ça, `terraform validate` et `terraform test` dans les modules utilisent
le binaire local — pratique pour itérer sur des modifs schema avant release.

---

## Versionnage

SemVer aligné conceptuellement avec le provider. **Latest : `v0.19.0`** (compatible provider `>= 3.0.0`).

- `v0.1.x` : compatible provider `>= 0.7.1`
- `v0.2.x` : compatible provider `>= 0.8.0` (nouveaux champs scale-set / DB credentials)
- `v0.4.x` : compatible provider `>= 0.10.0` (ajoute `managed/registry` — CCR Phase 6)
- `v0.5.x` : compatible provider `>= 0.11.1` (ajoute `managed/iam-role` + 3 atomic IAM + landing-zone `iam-team-segregation` — IAM Roles v1)
- `v0.7.x` : compatible provider `>= 0.13.0` (ajoute `atomic/secret` — Secret Manager v1)
- `v0.8.x` : compatible provider `>= 0.14.0` (ajoute Application Gateway v1 : 3 atomic + 1 composable + option appgw dans `basic-web-app`)
- `v0.17.x` : compatible provider `>= 1.1.2` (local name canonique `cetic-cloud-platform`, attr `provider = cetic-cloud-platform` obligatoire sur ~85 blocs)
- `v0.18.0` (2026-05-28) : compatible provider `>= 2.0.0`. **BREAKING amont** — si un consumer utilisait encore `data "ccp_lxc_templates"` ou `data "ccp_qemu_templates"` (retirés en provider v2.0.0), migrer vers `data "ccp_container_templates"` / `data "ccp_vm_templates"`. PR #19 — 46 fichiers patchés.
- `v0.18.1` (2026-05-29) : fix `storage/block-volume` — `attach_to.type` mappe l'alias legacy `vm_instance` → `vm` + accepte `vm` (le provider rejetait `vm_instance` depuis v0.24+). Rétro-compatible. PR #21.
- `v0.18.2` (2026-05-29) : `managed/k8s-cluster` — var `public_ip_id` (éphémère, retiré en v0.19.0). PR #22.
- `v0.19.0` (2026-05-29) : compatible provider **`>= 3.0.0`** (cascade 39 versions.tf). `managed/k8s-cluster` — retrait du var `public_ip_id` (le provider v3 a fusionné les deux attributs) ; **`apiserver_public_ip_id` est désormais mutable** (attach/détach/rotate sans ForceNew, via le provider). PR #24.

**Convention** : on bump le provider constraint dès qu'une feature client (matérialisée par un changement de schéma upstream) requiert la nouvelle version. Les patch-only du provider (docs, anti-leak, sub-cent pricing seed) n'imposent pas un bump module sauf si une migration aliase est en jeu (cas v0.18.0 vs provider v2.0.0).
