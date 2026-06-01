# Changelog

All notable changes to `cetic-cloud-terraform-modules` are documented here.
Format suit [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) ; le projet
suit [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
+      version = ">= 4.0.0"
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
