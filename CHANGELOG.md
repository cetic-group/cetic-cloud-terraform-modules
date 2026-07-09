# Changelog

All notable changes to `cetic-cloud-terraform-modules` are documented here.
Format suit [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) ; le projet
suit [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.33.0]

**Contrainte `versions.tf` volontairement INCHANGÉE (`>= 5.0.0`)** — le provider
attendu pour cette feature (`disk_gb`/`storage_gb` Optional+Computed) n'est pas
encore publié côté Registry à ce commit (dernier tag réel : `v5.4.0`). Bumper le
plancher `versions.tf` vers un numéro de version qui n'existe pas casse
`terraform init` sur les **42 modules** (`no available releases match the given
constraints`), pas seulement `terraform validate` sur les modules touchés — voir
l'avertissement en fin de section. Le bump de contrainte sera fait dans un commit
de suivi, une fois la release provider réelle connue.

### Added — dimensionnement disque/stockage à la carte (`disk_gb` / `storage_gb`, #577/#578)

- Nouvelle variable **`disk_gb`** (Optional, `number`, défaut `null`) sur
  `compute/container`, `compute/vm`, `compute/container-scale-set` et
  `compute/vm-scale-set` : taille du disque racine (ou de chaque réplica pour
  les scale sets) en GB. `null` = taille par défaut du plan (`plan`).
  **Grow-only** : augmenter la valeur redimensionne le disque en place ; une
  valeur inférieure à la taille courante est refusée par l'API (422). Câblée
  directement sur l'attribut `disk_gb` de la resource (Optional+Computed côté
  provider). Nouveaux outputs `disk_gb` sur `compute/container-scale-set` et
  `compute/vm-scale-set` (parité avec `compute/container`/`compute/vm`, qui
  l'exposaient déjà en output Computed-only).
- `managed/k8s-cluster` : la même variable `disk_gb` est ajoutée à l'objet
  **`initial_pool`** et à chaque entrée de la map **`additional_pools`** —
  taille du disque racine des **workers** de ce pool, indépendante du disque
  du control plane. Même sémantique grow-only. Nouvel output
  **`additional_pool_disk_gb`** (map nom de pool → taille effective, miroir de
  `additional_pool_k8s_versions`).
- `managed/registry` : nouvelle variable **`storage_gb`** (Optional, `number`,
  défaut `null`) — quota de stockage de la registry. `null` = défaut
  plateforme. Grow-only. Nouvel output `storage_gb` (quota effectif, distinct
  de `storage_used_gb` déjà existant).
- Exemples mis à jour : `compute/vm` (README), `compute/container-scale-set`
  (README), `compute/vm-scale-set` (README), `managed/k8s-cluster` (README,
  `initial_pool.disk_gb` + `additional_pools.*.disk_gb`), `managed/registry`
  (README), et `landing-zones/basic-web-app` (le container applicatif fixe
  `disk_gb` au-delà du défaut du plan).
- Tests `tftest` ajoutés : `compute/vm` (`disk_gb_passthrough`),
  `compute/vm-scale-set` (`disk_gb_passthrough`), `managed/k8s-cluster`
  (`initial_pool_disk_gb_passthrough`, `additional_pool_disk_gb_passthrough`),
  `managed/registry` (`storage_gb_passthrough`).

⚠️ **Cascade en avance de phase sur le provider** (même situation que
`network/vpc-peering` en 0.32.0) : au moment de cette release, le provider
publié sur le Registry (`v5.4.0`) expose encore `disk_gb` en **lecture seule**
(Computed-only) sur `ccp_vm_instance`/`ccp_container_instance`, et
`disk_gb`/`storage_gb` n'existent pas du tout sur les scale-sets, le node pool
K8s et la registry. `terraform validate`/`terraform test` échouent donc sur
`compute/container`, `compute/vm`, `compute/container-scale-set`,
`compute/vm-scale-set`, `managed/k8s-cluster` et `managed/registry` (et sur
`landing-zones/basic-web-app`, qui compose `compute/container`) tant qu'une
version provider rendant ces attributs Optional+Computed n'est pas publiée —
cela inclut temporairement des runs `tftest` qui passaient avant ce commit (le
simple fait de référencer `disk_gb = var.disk_gb` dans une resource où
l'attribut réel est encore Computed-only fait échouer `terraform validate`
avant même l'exécution des `run` blocks). `terraform fmt -recursive` reste
propre. Une fois la version provider réelle publiée : (1) bumper la contrainte
`versions.tf` (commit de suivi, cf. convention de bump plus haut dans
`CLAUDE.md`), (2) tout redevient vert sans autre changement de ce repo.

## [0.32.0]

Nouveau module **`network/vpc-peering`**, wrappant la resource
`ccp_vpc_peering` (peering VPC↔VPC, pendant de `network/vnet-peering` pour les
VNets). Variables `vpc_a_id`/`vpc_b_id`, outputs `id`/`status`. Contrainte
provider inchangée `>= 5.0.0`. **Shippé en avance de phase** : `ccp_vpc_peering`
n'existe pas encore côté Registry à ce commit, donc pas de `tests/` (rien de
mockable tant que la resource n'est pas définie) ; `terraform validate` sur ce
module reste rouge jusqu'à la release provider correspondante. Entrée de
rattrapage — absente à tort du CHANGELOG initial (commit `0eff084`, tag
`v0.32.0` déjà posé sur `main`).

## [0.31.0]

Aligné sur le provider `cetic-group/ccp` **v5.0.0** (la contrainte reste
`>= 5.0.0` — les nouveaux attributs CCKS ci-dessous font partie de la série v5.0.0).

### Added — choix de l'OS des nodes + version Kubernetes par pool (`managed/k8s-cluster`)

- Nouvelle variable **`os_image`** (Optional, défaut `null`) sur
  `managed/k8s-cluster` : famille de système d'exploitation des nodes du cluster
  — `flatcar` (défaut plateforme), `ubuntu` ou `rocky9`. **Immuable** (recrée le
  cluster). Câblée sur `ccp_k8s_cluster.os_image`. Validation
  `flatcar|ubuntu|rocky9` (ou `null`). Nouvel **output `os_image`** (famille
  effective lue en retour).
- Champ **`k8s_version`** ajouté à l'objet **`initial_pool`** (Optional) et à
  chaque entrée de **`additional_pools`** (Optional) : version Kubernetes des
  **workers** de ce pool. Omis = hérite de la version du **plan de contrôle**
  (la variable `k8s_version` du cluster, dont le sens est désormais explicitement
  « plan de contrôle »). Doit rester `<=` à la version du plan de contrôle.
  Mutable (montée de version rolling, **pas** de recréation du pool). Câblé sur
  `ccp_k8s_cluster.initial_pool.k8s_version` et `ccp_k8s_node_pool.k8s_version`.
  Nouveaux outputs **`k8s_version`** (plan de contrôle) et
  **`additional_pool_k8s_versions`** (map nom de pool → version worker effective).
- `landing-zones/k8s-platform` : nouvelle variable passthrough **`os_image`**
  (+ output `cluster_os_image`) ; l'objet `additional_pools` expose désormais
  `k8s_version` par pool. Reste fonctionnel sans `os_image` (défaut plateforme).
- 4 runs `tftest` ajoutés (`os_image_passthrough`, `rejects_invalid_os_image`,
  `initial_pool_k8s_version_passthrough`, `additional_pool_k8s_version_passthrough`) ;
  16 runs au total, tous verts.

## [0.30.0]

Aligné sur le provider `cetic-group/ccp` **v5.0.0** (Windows sur VM/VMSS +
retrait de la ressource `ccp_windows_instance` legacy).

### Added — support Windows sur `compute/vm` et `compute/vm-scale-set`

- Nouvelle variable **`windows_license_consent`** (bool, défaut `false`) sur
  `compute/vm` et `compute/vm-scale-set` : reconnaître que CETIC Cloud ne fournit
  pas les licences Windows. Obligatoire (`true`) quand `template` est une image
  système Windows (`win-*`) ou un template custom capturé depuis une VM Windows
  (l'API renvoie 422 sinon). Ignoré pour Linux. Windows exige aussi un plan
  `medium`+ et un mot de passe administrateur fort (≥ 12 caractères, ≥ 3
  catégories).
- Nouvel **output `os_family`** (`linux` | `windows`) sur les deux modules.
- Nouvel **exemple `examples/windows-vm`** (VM Windows + VM scale set Windows, RDP).
- Tests `tftest` ajoutés sur `compute/vm` et `compute/vm-scale-set`.

### Changed

- **Cascade `versions.tf` → `>= 5.0.0`** sur les 41 modules / landing-zones /
  examples (plus aucun `>= 4.x`).

## [0.29.0] — 2026-06-13

Aligné sur le provider `cetic-group/ccp` **v4.9.0** (parité `ccp_bastion` ↔ `ccp_vpn_gateway`).

### Added — `managed/bastion` : nouveau module (bastion SSH standalone)

Le provider v4.9.0 enrichit la ressource `ccp_bastion` (parité avec
`ccp_vpn_gateway`) : `plan` (`small`/`medium`/`large`, défaut `small`, ForceNew),
`vpc_ids` (multi-VPC 1–5, Optional+Computed, le `vpc_id` primaire reste Required
et toujours inclus), `public_ip_id` (Optional+Computed) et `tags` + attribut
Computed `public_ip_address`. Aucun module n'enveloppait cette ressource
standalone (alors que `bastion_access` est câblé sur les 4 modules compute, et
qu'il existe `managed/vpn-gateway`).

Nouveau module **`modules/managed/bastion/`** calqué sur `managed/vpn-gateway` :

- **`variables.tf`** : `name` (1–100 chars, regex), `region` (`RNN`/`PAR`/`ABJ`),
  `plan` (défaut `small`), `vpc_ids` (liste) **ou** `vpc_id` (raccourci),
  `public_ip_id` (optionnel), `tags` (optionnel, ≤ 60 × ≤ 50 chars).
- **`main.tf`** : `ccp_bastion` avec normalisation VPC (`vpc_ids` prioritaire,
  VPC primaire dérivé, liste transmise uniquement en multi-VPC pour éviter un
  faux diff) + 2 `precondition` (≥ 1 et ≤ 5 VPC).
- **`outputs.tf`** : `id`, `status`, `endpoint_host`, `endpoint_port`,
  `public_ip_address`, `vpc_ids`.
- **`README.md`** : exemple, tableaux Inputs/Outputs, notes (immutabilité,
  provisioning asynchrone, ordre de destruction `depends_on = [module.vpc]`,
  distinction avec `bastion_access` des modules compute).
- **`tests/bastion.tftest.hcl`** : `mock_provider` + 5 runs nominaux
  (single-VPC, multi-VPC + plan + tags, public_ip, …) et 5 runs de rejet
  (region/plan/name/tags invalides, 0 VPC, > 5 VPC).

### Changed — cascade `versions.tf` → `>= 4.9.0`

Bump de **tous** les `versions.tf` (modules / landing-zones) à la contrainte
provider **`>= 4.9.0`** (40 fichiers : 35 depuis `>= 4.4.0`, 4 compute depuis
`>= 4.8.0`, 1 vpn-gateway depuis `>= 4.7.0`) — convention de cascade du CLAUDE.md.
Plus aucun plancher résiduel à 4.4.0 / 4.7.0 / 4.8.0.

## [0.28.0] — 2026-06-12 (rattrapage doc)

Aligné sur le provider `cetic-group/ccp` **v4.8.0** (#343 — stats accès/réseau,
`bastion_access` write-only sur instances / scale-sets / templates).

### Added — `compute/*` : argument `bastion_access`

Les 4 modules compute (`compute/container`, `compute/vm`,
`compute/container-scale-set`, `compute/vm-scale-set`) exposent l'argument
**`bastion_access`** (bool, défaut `false`), câblé sur la ressource sous-jacente.
Activé, il autorise le bastion du VPC à atteindre l'instance / les membres du
scale-set en SSH (accès write-only côté provider). Contrainte provider bumpée à
**`>= 4.8.0`** sur les `versions.tf` de ces 4 modules.

> Note : cette entrée documente après coup le travail livré en arbre sans entrée
> CHANGELOG (le journal s'arrêtait à 0.27.0).

## [0.27.0] — 2026-06-11

Aligné sur le provider `cetic-group/ccp` **v4.7.0** (support VPN site-à-site).

### Added — `managed/vpn-gateway` : peers site-à-site (`peer_type` + `site_cidrs`)

Le provider v4.7.0 ajoute à `ccp_vpn_peer` les attributs `peer_type`
(`client` | `site`, défaut `client`) et `site_cidrs` (sous-réseaux distants,
obligatoire pour un peer `site`). Le module les expose désormais :

- **`variables.tf`** : l'objet `peers` gagne `peer_type` (optional, défaut
  `client`) et `site_cidrs` (optional, défaut `[]`). Trois validations ajoutées :
  `peer_type ∈ {client, site}` ; un peer `site` exige au moins un `site_cidrs`
  tandis qu'un `client` doit le laisser vide ; chaque `site_cidrs` doit être un
  CIDR IPv4 valide.
- **`main.tf`** : `peer_type` et `site_cidrs` câblés sur chaque `ccp_vpn_peer`
  (`site_cidrs` envoyé uniquement pour les peers `site`).
- **`outputs.tf`** : l'output `peers` inclut `peer_type` et `site_cidrs`.
- **`README.md`** : documentation des deux types (client = appareil unique /
  nomade ; site = réseau distant en site-à-site) + exemple d'usage avec un peer
  `site`. Notes d'immutabilité (`peer_type`/`site_cidrs` forcent le remplacement).
- **`tests/`** : `mock_provider` aliasé `site` + 4 runs ajoutés (création peer
  `site`, rejet `site` sans `site_cidrs`, rejet `client` avec `site_cidrs`, rejet
  `peer_type` invalide) ; assertion `peer_type` défaut `client` sur le run multi.

Contrainte provider **`>= 4.7.0`** sur `versions.tf` du module (le champ
`site_cidrs` requiert le provider v4.7.0). Rétro-compatible : les peers existants
sans `peer_type` restent des `client`.

## [0.23.2] — 2026-06-02

### Fixed — plans AppGW : clés canoniques `appgw-*` (alias `small`/`medium`/`large`)

L'API valide les plans AppGW contre le catalogue `compute_plans` (kind=`appgw`),
dont les clés sont **`appgw-small` / `appgw-medium` / `appgw-large`**. Les modules
validaient uniquement les formes courtes → toute création échouait en 422.

- **`atomic/application-gateway`** : la variable `plan` accepte les clés canoniques
  `appgw-*` ET les alias courts (`small`/`medium`/`large`), normalisés vers la clé
  canonique avant l'appel API (même pattern que l'alias `vm_instance` → `vm` de
  `storage/block-volume` v0.18.1). Défaut : `appgw-small`. Test `accepts_canonical_plan_key`.
- **`managed/application-gateway`**, **`exposure/web-app-with-appgw`**,
  **`landing-zones/web-app-with-tls`**, **`landing-zones/basic-web-app`** :
  validations relâchées de la même façon (passthrough vers l'atomic qui normalise).
- Contrainte provider **`>= 4.1.1`** sur les 5 modules AppGW (le provider v4.1.1
  retire sa propre validation client-side en dur — les deux fixes vont ensemble).

Rétro-compatible : les consommateurs qui passaient `small`/`medium`/`large` obtiennent
désormais la clé canonique côté API (au lieu d'un 422).

## [0.23.1] — 2026-06-02

### Fixed — `landing-zones/vpc-design*` : refs de modules alignées

- Les landing-zones `vpc-design` / `vpc-design-peering` référençaient encore
  `?ref=v0.3.4` et l'ancienne adresse du provider. Refs alignées sur le repo courant. PR #28.

## [0.23.0] — 2026-06-02

Aligné sur le provider `cetic-group/ccp` **v4.1.0**. Cascade : contrainte
`>= 4.0.0` → **`>= 4.1.0`** sur tous les `versions.tf`, le README racine et les
exemples.

### Added — `network/public-ip` : `quantity` / `label` / `description`

- Nouvelles variables `quantity` (1-8, défaut 1), `label` (max 100 chars) et
  `description`. Quand `quantity > 1`, le `label` est automatiquement suffixé
  `-1`, `-2`, … La ressource passe en `count = var.quantity`.
- Outputs singuliers (`id`, `ip_address`, `status`, `attached_to_id`,
  `attached_to_type`) **rétro-compatibles** — pointent désormais sur la 1re IP
  (`ccp_public_ip.this[0]`). Ajout de `label` + `description` singuliers.
- Nouveaux outputs **liste** : `ids`, `ip_addresses`, `labels`.
- Tests `tests/public_ip.tftest.hcl` (quantité, suffixage du label, rejet
  `quantity = 9`).

### Changed — `exposure/load-balancer` : schéma listener aligné + ACME (BREAKING)

- La variable `listeners` est réécrite pour matcher le schéma réel
  `ccp_load_balancer.listener` du provider :
  * `protocol` accepte désormais `tcp` | `http` | **`https`**.
  * `frontend_port` → **`listen_port`**.
  * `algorithm` : `round_robin`/`least_conn`/`source_ip` → **`roundrobin`/`leastconn`/`source`**.
  * Ajout de `health_check_enabled`, `health_check_path`, `domain`,
    `acme_challenge` (`http01`/`dns01`), `acme_dns_provider`,
    `acme_dns_credentials` (sensible) — certificats Let's Encrypt automatiques.
  * Le `name` du listener est supprimé (la clé de map reste un label purement
    logique, non envoyé à l'API).
- Output `created_at` ajouté ; `status` documenté `provisioning`/`active`/`updating`/`error`.
- **Migration consumer** : renommer `frontend_port` → `listen_port`, et les
  valeurs d'`algorithm` (`round_robin` → `roundrobin`, etc.). Retirer tout
  `name` de listener.

### Changed — `atomic/appgw-listener` : ACME, retrait de `custom_domain` (BREAKING)

- La variable `custom_domain` (bool, no-op côté provider v4.1.0) est remplacée
  par `acme_challenge` (`http01`/`dns01`/`null`), `acme_dns_provider` et
  `acme_dns_credentials` (sensible) — câblés sur `ccp_appgw_listener`.
- Outputs : retrait de `custom_domain` ; ajout de `acme_challenge`,
  `acme_issued_at`, `acme_renew_after`.
- Les modules composites `exposure/web-app-with-appgw` et
  `managed/application-gateway` exposent désormais les mêmes champs ACME
  (`acme_challenge` défaut `http01`) à la place de `custom_domain`.
- Landing-zones : `basic-web-app` (`appgw_custom_domain` → `appgw_acme_challenge`
  + `appgw_acme_dns_provider`/`appgw_acme_dns_credentials`) et `web-app-with-tls`
  (`custom_domain = true` → `acme_challenge = "http01"`) mis à jour.
- **Migration consumer** : remplacer `custom_domain = true` par
  `acme_challenge = "dns01"` (+ `acme_dns_provider`/`acme_dns_credentials`) ou
  `acme_challenge = "http01"` selon le mode de validation souhaité.

## [0.22.0] — 2026-06-01

### Changed — provider renamed to `cetic-group/ccp` (local name `ccp`)

- The CETIC provider was renamed. Across the whole catalog (every
  `versions.tf`, `providers.tf`, example `main.tf`, README and docs):
  * Registry source `cetic-group/cetic-cloud-platform` → **`cetic-group/ccp`**.
  * Terraform local name `cetic-cloud-platform` → **`ccp`** (in
    `required_providers` declarations, `provider "…"` blocks and the
    `provider = …` attribute on every `resource "ccp_*"` / `data "ccp_*"`).
  * Provider version constraint bumped from `>= 3.2.0` to **`>= 4.0.0`**.
- Resource and datasource type names are **unchanged** — they keep the
  `ccp_*` prefix. Since the new local name (`ccp`) now matches that prefix,
  no `providers = { ... }` map is required on module calls (Terraform
  auto-resolves).

### Migration for consumers

```diff
 terraform {
   required_providers {
-    cetic-cloud-platform = {
-      source  = "cetic-group/cetic-cloud-platform"
-      version = ">= 3.2.0"
+    ccp = {
+      source  = "cetic-group/ccp"
+      version = ">= 4.3.0"
     }
   }
 }

-provider "cetic-cloud-platform" {}
+provider "ccp" {}

 module "vpc" {
   source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/vpc?ref=v0.22.0"
-  providers = { ccp = cetic-cloud-platform }
   ...
 }
```

## [0.18.0] — 2026-05-28

### Changed — bump provider constraint to `>= 2.0.0`

- Provider version constraint bumped from `>= 1.1.2` to `>= 2.0.0` across the
  catalog (every `versions.tf`, `providers.tf`, example `main.tf` and
  `README.md` snippet). Includes:
  * v1.1.3 — full ingress controller coverage on `ccp_k8s_cluster` doc + anti-leak cleanup
  * v1.1.4 — DB ×4 + LB missing params fix (`storage_gb`, `replicas`, `scale_set_id`, …)
  * v1.1.5 — sidebar category splits fix (Database/Databases, Network/Networking)
  * v1.2.0 — new `ccp_container_templates` + `ccp_vm_templates` datasources
  * v2.0.0 — **BREAKING**: removal of the deprecated `ccp_lxc_templates` +
    `ccp_qemu_templates` aliases

### Changed — docstring references to dropped datasources

- `landing-zones/{web-app-with-tls,basic-web-app}/variables.tf` —
  `description` strings pointing at `data.ccp_lxc_templates` updated to
  `data.ccp_container_templates` to match the v2 surface.

### Migration for consumers

If your root module pinned the provider to `~> 1.x`, you must bump to
`~> 2.0` and rename any `data "ccp_lxc_templates"` /
`data "ccp_qemu_templates"` to their v2 canonical names:

```diff
- data "ccp_lxc_templates" "available" {}
+ data "ccp_container_templates" "available" {}

- data "ccp_qemu_templates" "available" {}
+ data "ccp_vm_templates" "available" {}
```

Field access (`templates[*].key` / `display_name` / `is_default`) is
unchanged.

## [0.17.0] — 2026-05-28

### Changed — provider local name now `cetic-cloud-platform`

- Every `versions.tf` and `providers.tf` declares the provider with the
  canonical local name `cetic-cloud-platform` (matches the Terraform
  Registry's "Use Provider" snippet for `cetic-group/cetic-cloud-platform`).
  Resource type names continue with the fixed prefix `ccp_*`.
- All `resource "ccp_*"` / `data "ccp_*"` blocks inside modules,
  landing-zones and examples carry an explicit
  `provider = cetic-cloud-platform` attribute (required when the local
  name differs from the resource prefix).
- Provider version constraint bumped to `>= 1.1.2` across the catalog
  (includes the v1.0.0 cosmetic rename, v1.0.1 `attached_to_id` drift
  fix, v1.1.0 plan-time SNAT check + mutable `public_ip_id`, and the
  v1.1.2 hotfix for the k8s/db_credentials TypeName regression).
- Tests' `mock_provider "ccp"` renamed to `mock_provider "cetic-cloud-platform"`.

### Migration for consumers

The cleanest root-module pattern is now:

```hcl
terraform {
  required_providers {
    cetic-cloud-platform = {
      source  = "cetic-group/cetic-cloud-platform"
      version = "~> 1.1"
    }
  }
}

provider "cetic-cloud-platform" {}

module "vpc" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/vpc?ref=v0.17.0"
  # No `providers = { ... }` map needed — local names match.
  ...
}
```

Consumers still on `ccp` as their root local name can either switch (as
above) or pass `providers = { cetic-cloud-platform = ccp }` to each
module call.

## [0.15.0] — 2026-05-26

### Added — CCKS tier (HA control-plane exposure)

- **`modules/managed/k8s-cluster`** : nouvelle variable `tier`
  (string, défaut `"dev"`, validation `OneOf dev/prod`), propagée vers
  `ccp_k8s_cluster.tier` (provider ≥ 0.21.0). `dev` = frontal d'exposition
  unique (adapté dev/staging). `prod` = frontaux actif/passif + VIP
  flottante VNet pour la haute-disponibilité du plan de contrôle.
  Immuable (`ForceNew`).
- **`modules/managed/k8s-cluster`** : nouveaux outputs `tier`,
  `proxy_secondary_vmid`, `proxy_secondary_node`, `proxy_vip_vnet`
  (les trois derniers sont `null` en tier `dev`).
- **`landing-zones/k8s-platform`** : nouvelle variable passthrough
  `k8s_tier` (défaut `"dev"`) et output `cluster_tier`.
- Tests `terraform test` (4 cas) sur `managed/k8s-cluster` :
  défaut `dev`, acceptation `prod`, rejet d'un tier invalide, rejet d'une
  région invalide.

### Changed

- **Bump global provider** : tous les `versions.tf` / `providers.tf` /
  examples / README passent à `>= 0.21.0`. Couvre le nouvel attribut
  `ccp_k8s_cluster.tier` et les 3 outputs Computed associés.

### Notes

- Pas de breaking change : `tier` est Optional avec default `"dev"` côté
  provider et module (= comportement legacy). Compatible rétro pour tous
  les consommateurs existants.
- Changement de tier post-création = recréation du cluster
  (`ForceNew`). Choisir le tier à la création.

## [0.13.0] — 2026-05-21

### Added — AppGW route `strip_prefix`

- **`modules/atomic/appgw-route`** : nouvelle variable `strip_prefix`
  (bool, défaut `false`), propagée vers `ccp_appgw_route.strip_prefix`
  (provider ≥ 0.19.0). Quand `true` et `path_match` non vide en mode
  `prefix`/`exact`, la gateway retire le préfixe de l'URL avant forward
  au backend (ex. `/web-app/foo` → `/foo`).
- **`modules/managed/application-gateway`** et
  **`modules/exposure/web-app-with-appgw`** : ajout de `strip_prefix`
  (bool, défaut `false`) au schéma `routes[*]`, passthrough vers le
  sous-module `atomic/appgw-route`.

### Changed

- **Bump global provider** : tous les `versions.tf` / `providers.tf` /
  examples / README passent de `>= 0.18.0` à `>= 0.19.0`. Couvre le
  nouvel attribut `ccp_appgw_route.strip_prefix`.

### Notes

- Pas de breaking change : `strip_prefix` est Optional avec default
  `false` (= comportement legacy). Compatible rétro pour tous les
  consommateurs existants.

## [0.12.0] — 2026-05-20

### Added — Load Balancer plan tiers

- **`modules/exposure/load-balancer`** : nouvelle variable `plan`
  (string, défaut `"small"`, validation `OneOf small/medium/large`),
  propagée vers le resource provider `ccp_load_balancer.plan`
  (provider ≥ 0.18.0). Compatible rétro : sans bump explicite côté
  consommateur, le LB conserve le tier `small` par défaut.
- **`landing-zones/basic-web-app`** : nouvelle variable `lb_plan`
  (string, défaut `"small"`) exposée en surface pour piloter la
  capacité du LB quand `exposure_type = "lb"`. README mis à jour.

### Changed

- **Bump global provider** : tous les `versions.tf` / providers.tf /
  examples / README (41 fichiers au total) passent de `>= 0.16.0` ou
  `>= 0.17.0` à `>= 0.18.0`. Couvre le nouvel attribut
  `ccp_load_balancer.plan` ainsi que les ajouts cumulés de la v0.17.0
  (support plans).

### Notes

- `plan` côté provider est `Optional+Computed+Default("small")` avec
  `RequiresReplace()` — un consommateur qui passe de `small` à `medium`
  via `terraform apply` verra un destroy+create de la ressource. Aucun
  redimensionnement en place de la paire LB (limitation plateforme).

## [Unreleased] — Billing v2

### Added

- **`modules/managed/billing-budget`** — module composé qui combine
  `ccp_budget` + optionnel `ccp_commit`. Cap mensuel en euros (converti
  en cents), alertes 50/80/100% configurables, hard-stop à 100%, et
  engagement `monthly` (-10%) / `yearly` (-20%) activable en une variable.
  Compatible provider ≥ 0.16.0.

### Changed

- **Bump global provider** : tous les `versions.tf` passent à `>= 0.16.0`
  (auparavant `>= 0.14.0` / `>= 0.15.0`). Couvre les nouvelles resources
  / datasources billing v2 : `ccp_pricing`, `ccp_promo_codes_available`,
  `ccp_budget`, `ccp_commit`.

## [Unreleased précédent] — Application Gateway v1 complétion

### Added

- **`modules/atomic/appgw-listener`** — nouveau module 1-1 sur
  `ccp_appgw_listener` (provider ≥ 0.14.0). Permet de déclarer 1 hostname +
  1 cert Let's Encrypt indépendamment de l'AppGW parente.
  Outputs riches : `acme_status`, `acme_last_renewal_at`, `cert_path`.
- **`modules/atomic/appgw-target-group-member`** — nouveau module 1-1 sur
  `ccp_appgw_target_group_member`. Utile pour ajouter dynamiquement un
  backend dans un target group ou piloter `enabled=false` (drain) sur un
  member précis sans toucher au reste du pool.
- **`modules/managed/application-gateway`** — nouveau composable haut-niveau
  qui orchestre AppGW + listeners + target groups + routes en un seul
  `module` block. S'appuie sur les 4 modules `atomic/appgw-*` (gateway,
  listener, target-group, route). Pendant L7 de `managed/registry` et
  `managed/database`.
- **`landing-zones/web-app-with-tls`** — nouvelle landing zone single-tenant
  pour exposer 1 container backend sur 1 domaine client (HTTPS auto via
  ACME DNS-01) avec WAF et basic auth optionnels. Vise le cas simple
  (admin panel, dashboard) — pour multi-instance / multi-route, utiliser
  directement `managed/application-gateway`.

### Changed

- **`modules/atomic/appgw-route`** — breaking change interne (input renommé).
  - **Supprimé** : variable `basic_auth_secret_ref` (qui ne correspondait à
    aucun input réel du provider — `basic_auth_secret_ref` est uniquement
    Computed côté `ccp_appgw_route`).
  - **Ajouté** : variable `basic_auth_users = list(object({user, password}))`
    `sensitive = true`, propagée vers le nested block `basic_auth_user` du
    provider via `dynamic`. Les mots de passe sont persistés en clair dans
    le state Terraform (cf. README) et hashés server-side dans une entrée
    Secret Manager.
  - **Ajouté** : output `basic_auth_secret_ref` (référence opaque retournée
    par le provider, `sensitive = false` car non exploitable seule).
  - Tests mis à jour : nouveau cas `creates_route_with_basic_auth`, nouveau
    cas `rejects_empty_user_in_basic_auth`.
- **`modules/exposure/web-app-with-appgw`** — propage le rename
  `basic_auth_secret_ref` → `basic_auth_users` dans le schéma
  `routes[*].policies`. README mis à jour avec un exemple basic auth.

### Notes

- Aucun bump de version provider requis : tout repose sur le provider
  `>= 0.14.0` déjà supporté. La feature `basic_auth_user` (nested block)
  existe depuis la release Application Gateway v1 (provider v0.14.0).
- **Migration** des consumers qui utilisaient `basic_auth_secret_ref`
  côté module : remplacer par `basic_auth_users` et déplacer le contenu du
  Secret Manager hors-bande vers des variables Terraform (`var.alice_password`).
  L'ancien attribut ne fonctionnait de toute façon pas (provider ne le
  prenait pas en input — c'était un no-op silencieux).
- Tag SemVer recommandé : **`v0.8.0`** quand prêt à release — minor bump
  par rapport à `v0.7.x` (nouveaux modules, breaking change interne sur un
  module récent dont aucun consumer prod ne dépend encore).

---

## [0.7.0] — 2026-05-13

### Added

- `modules/atomic/secret` — Secret Manager v1 (provider ≥ 0.13.0).

## [0.6.0] — 2026-05-13

### Changed (breaking)

- `compute/*` : `root_password` désormais obligatoire (provider ≥ 0.12.0).

## [0.5.0] — 2026-05-12

### Added

- `modules/managed/iam-role` + 3 atomic IAM (`iam-role`, `iam-role-assignment`,
  `service-account`) — IAM Roles v1 (provider ≥ 0.11.0).
- `landing-zones/iam-team-segregation`.

## [0.4.0] — 2026-05-10

### Added

- `modules/managed/registry` — CETIC Container Registry (CCR) (provider ≥ 0.10.0).
