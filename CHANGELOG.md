# Changelog

All notable changes to `cetic-cloud-terraform-modules` are documented here.
Format suit [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) ; le projet
suit [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
