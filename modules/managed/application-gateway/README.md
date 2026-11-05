# Module `managed/application-gateway`

Composable haut-niveau qui orchestre une **Application Gateway L7 complète** en un seul `module` block :

- 1 `application_gateway` (via `atomic/application-gateway`)
- N listeners (via `atomic/appgw-listener` — 1 par hostname)
- M target groups (via `atomic/appgw-target-group` — algorithm + health check + members in-place)
- K routes (via `atomic/appgw-route` — listener × path → target group, + policies + basic auth)

C'est le pendant **L7** de `managed/registry` ou `managed/database` : un service géré côté plateforme dont on déclare l'intent métier (hostnames, pools, règles) sans plomberie.

> **🇬🇧** High-level composable that bundles `application_gateway` + listeners + target groups + routes in one module call. The L7 counterpart of `managed/registry` and `managed/database`.

> 💡 Pour un cas plus simple (1 stack web 3-tier avec exposition AppGW automatique), voir la landing-zone `landing-zones/web-app-with-tls` ou l'option `exposure_type="appgw"` de `basic-web-app`.

## Exemple — API + admin avec routing path-based, HSTS, WAF et basic auth

```hcl
module "appgw_public_ip" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/public-ip?ref=v0.8.0"
  region = "RNN"
}

module "web" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/managed/application-gateway?ref=v0.8.0"

  name         = "acme-web"
  region       = "RNN"
  plan         = "medium"
  vpc_id       = module.vpc.vpc_id
  vnet_id      = module.vpc.vnet_ids.web
  public_ip_id = module.appgw_public_ip.id

  hostnames      = ["api.example.com", "admin.example.com"]
  acme_challenge = "http01" # certs Let's Encrypt — CNAME vers la gateway requis avant apply
  hsts_enabled   = true

  target_groups = {
    api = {
      algorithm = "leastconn"
      health_check = {
        path          = "/healthz"
        expect_status = 200
        interval_sec  = 10
      }
      members = {
        api_01 = { container_id = ccp_container_instance.api_01.id, port = 8080 }
        api_02 = { container_id = ccp_container_instance.api_02.id, port = 8080 }
      }
    }
    admin = {
      members = {
        admin_01 = { container_id = ccp_container_instance.admin.id, port = 4000 }
      }
    }
  }

  routes = [
    {
      listener_index   = 0 # api.example.com
      target_group_key = "api"
      priority         = 10
      policies = {
        rate_limit_per_sec = 500
        cors_enabled       = true
        cors_origins       = ["https://app.example.com"]
        cors_credentials   = true
        waf_preset         = "strict"
      }
    },
    {
      listener_index   = 1 # admin.example.com
      target_group_key = "admin"
      priority         = 10
      policies = {
        allow_cidrs = ["203.0.113.0/24"]
        basic_auth_users = [
          { user = "alice", password = var.alice_password },
          { user = "bob", password = var.bob_password },
        ]
        waf_preset = "strict"
      }
    },
  ]
}

output "url" {
  value = module.web.url   # https://api.example.com
}

output "acme_status" {
  value = module.web.listener_acme_status
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | string | yes | — | Nom de la gateway. |
| `region` | string | yes | — | `RNN` / `PAR` / `ABJ`. |
| `plan` | string | no | `"small"` | `small` / `medium` / `large`. |
| `vpc_id` | string | yes | — | UUID du VPC. |
| `vnet_id` | string | yes | — | UUID du VNet de la VIP. |
| `public_ip_id` | string | no | `null` | UUID IP publique (`null` = AppGW interne). |
| `tags` | list(string) | no | `[]` | |
| `force_https` | bool | no | `true` | |
| `hsts_enabled` | bool | no | `false` | |
| `hsts_max_age` | number | no | `31536000` | |
| `global_rate_limit_per_sec` | number | no | `null` | |
| `global_allow_cidrs` | list(string) | no | `[]` | |
| `global_deny_cidrs` | list(string) | no | `[]` | |
| `trust_proxy_headers` | bool | no | `false` | |
| `hostnames` | list(string) | yes | — | 1 listener par hostname (référencé par index dans `routes`). |
| `acme_challenge` | string | no | `"http01"` | `http01` / `dns01` / `null` (pas de cert). Appliqué à tous les hostnames. |
| `acme_dns_provider` | string | no | `null` | Clé provider DNS pour `dns01` (ex. `cloudflare`). |
| `acme_dns_credentials` | map(string) | no | `null` | Credentials DNS pour `dns01` (sensible, write-only). |
| `target_groups` | map(object) | yes | — | Voir schéma `atomic/appgw-target-group`. |
| `routes` | list(object) | yes | — | Voir schéma ci-dessous. Le sub-champ `basic_auth_users` est marqué sensitive par l'atomic sous-jacent. |

### Schéma `routes[*]`

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `listener_index` | number | required | Index dans `hostnames` (0-based). |
| `target_group_key` | string | required | Clé dans `target_groups`. |
| `priority` | number | `100` | Unique par AppGW, asc. |
| `path_match` | string | `"/"` | Pattern. |
| `path_match_type` | string | `"prefix"` | `prefix` / `exact` / `regex`. |
| `method_match` | list(string) | `[]` | |
| `strip_prefix` | bool | `false` | Strippe `path_match` avant forward backend (`/web-app/foo` → `/foo`). Mode `prefix`/`exact` uniquement. |
| `header_matches` | list(object) | `[]` | |
| `policies` | object | `{}` | Policies route-level (rate limit, CORS, headers, WAF, `basic_auth_users`). |

### Schéma `routes[*].policies.basic_auth_users[*]`

| Field | Type | Description |
|-------|------|-------------|
| `user` | string | Username (1-64). |
| `password` | string | Mot de passe en clair (1-256). Persisté en clair dans le state. |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `id` | no | UUID de la gateway. |
| `status` | no | `creating` / `active` / `error` / `deleting`. |
| `plan` | no | Plan effectif. |
| `region` | no | Région. |
| `vip_address` | no | VIP privée. |
| `public_ip_address` | no | IP publique attachée. |
| `hostnames` | no | Liste hostnames (input echo). |
| `listener_ids` | no | Map hostname → UUID. |
| `listener_acme_status` | no | Map hostname → `pending` / `issued` / `failed`. |
| `target_group_ids` | no | Map clé → UUID. |
| `target_group_member_ids` | no | Map clé → map(label → UUID member). |
| `route_ids` | no | Liste UUID routes. |
| `route_basic_auth_secret_refs` | no | Refs opaques Secret Manager par route (`null` si pas d'auth). |
| `url` | no | URL HTTPS du 1er hostname. |

## Notes

- **Ordre des hostnames stable** : `routes[*].listener_index` référence par position. Réordonner `hostnames` change la cible des routes — préférer ajouter en queue.
- **Reuse de target groups** : plusieurs routes peuvent pointer vers le même `target_group_key` (path-based avec policies différentes).
- **ACME** : `http01` exige que le hostname résolve vers l'IP publique de la gateway (CNAME/A) **avant** apply. `dns01` exige `acme_dns_provider` + `acme_dns_credentials`. `acme_challenge = null` n'émet aucun certificat.
- **`basic_auth_users` — sensibilité state** : les mots de passe sont persistés en clair. Utiliser un backend chiffré (S3+KMS, Vault, TFC). La plateforme ne les rend jamais ; au `terraform import`, les blocs sont vides et un `apply` les re-synchronise.
- **Migration depuis `exposure/web-app-with-appgw`** : signature identique côté inputs (à l'exception du nom du chemin source). Permuter `source` suffit ; pas de breaking change ni de drift d'état attendu.

## Cache HTTP déterminé par le plan (provider 8.0+)

Activez `cache_enabled` sur la passerelle et le cache sur les routes souhaitées.
Le plan attribue automatiquement le budget partagé et la taille maximale des
objets, y compris après un changement de plan. Consultez les outputs
`cache_size_mb`, `cache_max_object_kb`, `cache_effective_size_mb` et
`cache_size_limit_mb`. Les dimensions ne sont pas des variables du module.

Les routes acceptent `cache_mode` (`off`, `respect`, `force`),
`cache_default_ttl_s` (60), `cache_max_ttl_s` (3600), `cache_bypass_cookies`
(liste vide : toute requête avec cookie contourne le cache) et
`cache_debug_headers` (false). Dans les modules composés, ces attributs se
placent directement sur chaque objet `routes`, à côté de `path_match`.

Seuls les GET publics en 200 alimentent le cache ; HEAD peut lire ces entrées.
Authorization, Set-Cookie et les réponses privées restent exclus.
La purge est disponible dans la console, l'API ou `cetic appgw cache purge`.

### Migration

Cette version nécessite le provider 8.0.0 ou supérieur et l'API avec le cache
piloté par le plan. Le provider doit être publié avant l'utilisation de ces
modules. Les tests de la PR utilisent un binaire de développement isolé.

Si vous utilisiez la branche expérimentale de cache, retirez les arguments
`cache_size_mb` et `cache_max_object_kb` de vos appels de module. Conservez
`cache_enabled`, `plan` et les règles des routes. Mettez à jour la contrainte
provider puis exécutez `terraform init -upgrade` et examinez `terraform plan`.
La migration garde les adresses de ressources et les clés d'état ; elle ne
nécessite ni suppression d'état ni réimportation.

> **EN:** The selected plan owns both cache dimensions. Only enablement and
> route policies are configurable. Remove legacy size arguments, upgrade to
> provider 8.0+ once released, and review the plan. Existing state and resource
> addresses are retained. Upgrade Terraform clients before rolling out the
> plan-managed API; the 7.3 provider can report inconsistent results with it.

### Nombre d'instances (`replica_count`)

`replica_count` vaut `2` par défaut (haute disponibilité). La valeur `1`
convient aux environnements qui acceptent une interruption en cas de panne
ou maintenance de leur instance unique. Le plan fixe la capacité de chaque
instance ; il ne détermine pas leur nombre. Le modifier recrée la ressource.
La sortie `replica_count` restitue la valeur provisionnée.

Nécessite le provider **8.0.0** et une plateforme prenant en charge ce champ.
Mettre la plateforme à jour avant de demander le mode unique. Le provider
peut être installé auparavant en conservant la valeur historique `2`.
Le catalogue définit des tarifs distincts pour une et deux instances. Chaque
montant couvre déjà toutes les instances du mode choisi ; le module ne
multiplie pas ce montant.

### Option cache payante

`cache_enabled` active ou désactive l'option cache HTTP. Le catalogue publie
son supplément sous `appgw_cache` pour le plan et le nombre d'instances choisis.
Ce supplément s'ajoute au tarif de base ; aucun montant n'est fixé ou calculé
par le module. Le budget et la taille maximale d'objet restent ceux du plan.
Consulter l'estimation de la plateforme avant activation, par exemple :

```bash
cetic billing estimate appgw --plan small --replica-count 1 --cache-enabled
```

Le tarif de la combinaison doit être disponible sur la plateforme pour activer
l'option. La désactivation du cache reste possible.


### Politiques d’accès (#1828)

Terraform 1.9 minimum (validation des domaines entre variables).

Les entrées `l4_policy`, `l7_policy` et `client_ip_policy` de la passerelle,
et `l7_policy` des listeners/routes, utilisent les objets typés du provider
**8.1.0 minimum** (publication requise avant livraison de ces modules).
Une valeur omise ou `null` conserve la protection distante, notamment après
import ; `{}` demande explicitement sa suppression. Les maps `policies`,
`allow_rules`, `deny_rules` et `required_headers` sont indexées par des clés
stables. `match.headers` est une liste de critères combinés par ET.

Une autorisation locale ne contourne aucun refus hérité. TCP/80 restrictif
nécessite DNS-01/certificat importé ; une politique d’en-têtes exige le cache
`off` sur les routes concernées. Les domaines avec une route regex ne peuvent
pas activer les politiques L7. Le provider vérifie la capacité de l’API et la
convergence des instances avant d’annoncer la fin de la modification.

Pour les modules `managed/application-gateway` et `exposure/web-app-with-appgw`, `listener_l7_policies` est une map indexée par
hostname, et `routes[*].l7_policy` porte les règles propres à la route.
La landing zone expose les trois politiques de passerelle avec le préfixe `appgw_` ; pour une politique propre à un listener ou une route, utiliser les modules managed/exposure.
Le filtrage hérité `allow_cidrs` / `deny_cidrs` conserve son sens HTTP.
