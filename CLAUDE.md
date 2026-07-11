# cetic-cloud-terraform-modules — CLAUDE.md

> Modules Terraform officiels pour CETIC Cloud Platform.
> Repo public : https://github.com/cetic-group/cetic-cloud-terraform-modules
> Provider consommé : `cetic-group/ccp` (cf. `terraform-provider-cetic-cloud-platform/CLAUDE.md` pour la convention release ; le repo provider garde son nom de dossier historique).

---

## Convention bump version provider

À **chaque release** du provider Terraform `cetic-group/ccp`
(nouveau tag `vX.Y.Z`), mettre à jour systématiquement :

1. **`versions.tf` de chaque module / landing-zone / example** :
   ```hcl
   required_providers {
     ccp = {
       source  = "cetic-group/ccp"
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

## Pattern v4.0+ — local name `ccp` (provider renommé `cetic-group/ccp`)

Depuis les modules v0.22.0 + le provider v4.0.0, le provider a été renommé :
adresse Registry `cetic-group/ccp`, nom local Terraform `ccp` (les resource
types restent `ccp_*`). Tous les modules déclarent :

```hcl
# versions.tf de chaque module
terraform {
  required_version = ">= 1.7"
  required_providers {
    ccp = {
      source  = "cetic-group/ccp"
      version = ">= 4.3.0"
    }
  }
}
```

Comme le local name (`ccp`) **matche** désormais le préfixe des resource types
(`ccp_*`), Terraform auto-résout : un attribut `provider = ...` explicite sur
chaque bloc n'est **plus requis**. Les modules portent encore
`provider = ccp` (hérité de l'ancien pattern, inoffensif) ; on peut le garder
ou le retirer au gré des refactors.

Côté consommateur (root module), aucun `providers = {...}` map n'est nécessaire
sur les module calls — l'auto-résolution suffit. Le recommander dans les README.

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
mock_provider "ccp" {
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
    "cetic-group/ccp" = "/home/coul/Documents/techledger/cetic-group/terraform-provider-cetic-cloud-platform"
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

SemVer aligné conceptuellement avec le provider. **Latest : `v0.33.0`** (compatible provider `>= 5.0.0`, contrainte inchangée — cf. note ci-dessous, `v5.5.0` n'existe pas encore côté Registry).

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
- `v0.20.0` (2026-05-29) : compatible provider **`>= 3.1.1`** (cascade 39 versions.tf). `managed/k8s-cluster` — la var `initial_pool` expose `min_size`/`max_size` (optionnels) → autoscaler activable sur le pool initial (parité avec `additional_pools`). Les deux ensemble = activé ; retirés = désactivé (le provider envoie 0/0 depuis v3.1.1). 2 validations : set-ensemble + `max_size > min_size ≥ 0`. 3 tests `tftest` ajoutés (passthrough + 2 rejets). PR #25.
- `v0.21.0` (2026-05-29) : compatible provider **`>= 3.2.0`** (cascade 39 versions.tf). `managed/k8s-cluster` — la var `initial_pool` expose `labels` (map) + `taints` (liste `{key,value?,effect}`), parité complète avec `additional_pools` (mutables in-place). Câblés sur `ccp_k8s_cluster.initial_pool` (attributs `labels`/`taints`, pas des blocs). Validation `taint.effect`. 2 tests `tftest` (passthrough labels+taints + rejet effect invalide). PR #26.
- `v0.22.0` (2026-06-01) : renommage provider — adresse Registry `cetic-group/ccp`, local name `ccp`.
- `v0.23.0` (2026-06-02) : compatible provider **`>= 4.1.0`**. `network/public-ip` quantity/label/description ; alignement ACME LB + AppGW (`acme_challenge` http01/dns01, retrait `custom_domain` no-op). PR #27.
- `v0.23.1` (2026-06-02) : fix `landing-zones/vpc-design*` — refs de modules alignées sur le repo courant (ancien `?ref=v0.3.4` + ancienne adresse provider). PR #28.
- `v0.23.2` (2026-06-02) : fix plans AppGW — clés canoniques **`appgw-*`** acceptées + alias courts normalisés dans `atomic/application-gateway` (les validations en dur small/medium/large rejetaient les seules clés que l'API accepte → 422 systématique). Contrainte **`>= 4.1.1`** sur les 5 modules AppGW (le provider v4.1.1 retire sa validation client-side). PR #29.
- `v0.29.0` (2026-06-13) : compatible provider **`>= 4.9.0`**. **Nouveau module `managed/bastion`** (bastion SSH standalone, calqué sur `managed/vpn-gateway`) enveloppant `ccp_bastion` enrichi en v4.9.0 (`plan` défaut `small` / `vpc_ids` multi-VPC 1–5, `vpc_id` primaire toujours inclus / `public_ip_id` / `tags` + Computed `public_ip_address`). Inputs `name`/`region`/`plan`/`vpc_id`|`vpc_ids`/`public_ip_id`/`tags` ; outputs `id`/`status`/`endpoint_host`/`endpoint_port`/`public_ip_address`/`vpc_ids` ; 10 runs `tftest` mock_provider. **Cascade `versions.tf` → `>= 4.9.0`** (40 fichiers ; plus aucun 4.4.0/4.7.0/4.8.0).
- `v0.28.0` (2026-06-12) : compatible provider **`>= 4.8.0`** (cascade sur les 4 modules compute). Argument **`bastion_access`** (bool, défaut `false`) sur `compute/{container,vm,container-scale-set,vm-scale-set}` → autorise le bastion du VPC à joindre l'instance/les membres en SSH (#343). Entrée documentée en rattrapage (livré en arbre, CHANGELOG s'arrêtait à 0.27.0).
- `v0.30.0` : compatible provider **`>= 5.0.0`** (cascade 41 `versions.tf`). Support Windows sur `compute/vm` + `compute/vm-scale-set` (`windows_license_consent`, output `os_family`, exemple `examples/windows-vm`).
- `v0.31.0` : compatible provider **`>= 5.0.0`** (contrainte inchangée). `managed/k8s-cluster` — var **`os_image`** (`flatcar`/`ubuntu`/`rocky9`, défaut plateforme, ForceNew) + champ **`k8s_version`** par pool (`initial_pool` et `additional_pools`, Optional, `<=` plan de contrôle, mutable rolling). La var `k8s_version` du cluster = **plan de contrôle**. Outputs `os_image`/`k8s_version`/`additional_pool_k8s_versions`. LZ `k8s-platform` : passthrough `os_image` + `k8s_version` par pool. 4 tests `tftest` (16 verts).
- `v0.27.0` (2026-06-11) : compatible provider **`>= 4.7.0`** pour `managed/vpn-gateway`. La var `peers` expose `peer_type` (`client` défaut / `site`) + `site_cidrs` → support VPN **site-à-site** (peer `site` = réseau distant raccordé via son routeur ; `client` = appareil unique). 4 validations (XOR clé/managed déjà présent + `peer_type` ∈ {client,site} + `site`⇒`site_cidrs` non vide / `client`⇒vide + CIDR valides). Output `peers` enrichi (`peer_type`, `site_cidrs`). 4 tests `tftest` ajoutés (mock aliasé `site`). Aligné sur provider v4.7.0 (`ccp_vpn_peer.peer_type`/`site_cidrs`).
- `v0.32.0` : nouveau module **`network/vpc-peering`** (wrappe `ccp_vpc_peering`, calqué sur `vnet-peering` : vars `vpc_a_id`/`vpc_b_id`, outputs `id`/`status`). Contrainte inchangée `>= 5.0.0` — **shippé en avance de phase sur le provider** (`ccp_vpc_peering` n'existe pas encore côté Registry à ce commit) : `terraform validate`/`test` restent rouges sur ce module jusqu'à la release provider correspondante ; pas de `tests/` tant que la resource n'existe pas. Rattrapage doc (entrée absente à tort du CHANGELOG initial).
- `v0.33.0` (#577/#578) : **Dimensionnement disque/stockage à la carte** : nouvelle var **`disk_gb`** (Optional, number, `null` = défaut du plan, **grow-only**) sur `compute/{container,vm,container-scale-set,vm-scale-set}` + sur `managed/k8s-cluster.initial_pool` et chaque entrée de `additional_pools` (workers). Nouvelle var **`storage_gb`** (même sémantique) sur `managed/registry`. Outputs ajoutés en miroir : `disk_gb` (container-scale-set, vm-scale-set), `additional_pool_disk_gb` (k8s-cluster, map nom de pool → taille effective), `storage_gb` (registry, quota effectif — distinct de `storage_used_gb`, déjà existant). Câblage direct `attribut = var.xxx` (Optional+Computed côté provider ; `null` = omis, laisse le défaut serveur), même pattern que `network/vpc.cidr` (v0.23, PR #30). Exemples mis à jour (`compute/vm`, `compute/container-scale-set`, `compute/vm-scale-set`, `managed/k8s-cluster`, `managed/registry`) + `landing-zones/basic-web-app`. **Contrainte `versions.tf` volontairement INCHANGÉE (`>= 5.0.0`)** — le provider `v5.5.0` attendu pour cette feature n'est pas encore publié côté Registry (dernier tag réel : `v5.4.0`), et bumper le plancher vers une version inexistante casse `terraform init` sur **les 42 modules** (pas seulement ceux touchés — `no available releases match the given constraints`), contrairement à un simple échec de `validate`. Leçon tirée en session : NE JAMAIS committer un plancher `versions.tf` pointant une version non publiée, même en cascade « en avance de phase » (`v0.32.0`/vpc-peering l'avait déjà fait correctement en laissant `>= 5.0.0`). ⚠️ **Cascade en avance de phase sur le provider** (même situation que `v0.32.0`/`vpc-peering`) : au moment de cette release, le provider publié (`v5.4.0`) expose encore `disk_gb` en lecture seule (Computed-only, pas Optional) sur `ccp_vm_instance`/`ccp_container_instance`, et `disk_gb`/`storage_gb` n'existent pas du tout sur scale-sets/node-pool/registry → `terraform validate`/`terraform test` échouent sur les modules touchés (y compris des runs **déjà existants et verts avant ce commit**, ex. `compute/vm`/`compute/vm-scale-set`, car référencer un attribut Computed-only dans le HCL est une erreur de `validate`, peu importe sa valeur) tant qu'une version provider rendant ces attributs Optional+Computed n'est pas publiée **et** que la contrainte `versions.tf` n'est pas re-bumpée dans un commit de suivi (à faire séparément, une fois ce numéro de version confirmé réel). `terraform fmt -recursive` reste propre. Les nouveaux runs `tftest` ajoutés (passthrough `disk_gb`/`storage_gb`) documentent le comportement attendu et passeront sans modification dès que la dépendance amont est résolue.

**Convention** : on bump le provider constraint dès qu'une feature client (matérialisée par un changement de schéma upstream) requiert la nouvelle version. Les patch-only du provider (docs, anti-leak, sub-cent pricing seed) n'imposent pas un bump module sauf si une migration aliase est en jeu (cas v0.18.0 vs provider v2.0.0). **Cascade en avance de phase** (cf. `v0.32.0`/`v0.33.0`) : il est toléré de merger un module qui référence un attribut/une resource pas encore publiée côté Registry — le commit doit le dire explicitement, `terraform fmt` doit rester propre, et aucun test **pré-existant** ne doit être cassé par la modif (nouveau module sans tests, ou nouvel attribut sur un module déjà couvert → accepter que ses propres nouveaux runs restent rouges jusqu'à la release amont).
