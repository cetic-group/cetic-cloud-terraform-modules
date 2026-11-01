# Module `atomic/application-gateway`

Wrapper 1-1 autour de la resource provider `ccp_application_gateway`. Provisionne une **Application Gateway L7** (HTTP/HTTPS) avec terminaison TLS automatique, routing host/path et policies (rate limit, IP allow/deny, HSTS, CORS, headers, WAF) — pendant L7 du module `exposure/load-balancer` (qui reste pour le TCP/UDP brut).

Une AppGW = 1 IP publique flottante. Plusieurs hostnames partagent l'IP via SNI ; les routes (path + host + headers) sont déclarées séparément via `atomic/appgw-route`, les pools de backends via `atomic/appgw-target-group`.

> **🇬🇧** 1-1 wrapper around `ccp_application_gateway`. Provisions a L7 Application Gateway (HTTP/HTTPS) with TLS termination, host/path routing, and policies (rate limit, IP allow/deny, HSTS, CORS, headers, WAF). Pair with `atomic/appgw-route` and `atomic/appgw-target-group`. For raw TCP/UDP, use `exposure/load-balancer` instead.

## Exemple — minimal

```hcl
module "appgw_public_ip" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/network/public-ip?ref=v0.8.0"
  region = "RNN"
}

module "appgw" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/application-gateway?ref=v0.8.0"

  name         = "web-appgw"
  region       = "RNN"
  plan         = "medium"
  vpc_id       = module.vpc.vpc_id
  vnet_id      = module.vpc.vnet_ids.web
  public_ip_id = module.appgw_public_ip.id

  force_https   = true
  hsts_enabled  = true
  hsts_max_age  = 31536000
  tags          = ["env:prod", "team:web"]
}

output "appgw_url" {
  value = "https://${module.appgw.public_ip_address}"
}
```

## Exemple — gateway interne avec rate limit et allow-list

```hcl
module "appgw_internal" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/atomic/application-gateway?ref=v0.8.0"

  name        = "internal-api-appgw"
  region      = "RNN"
  plan        = "small"
  vpc_id      = module.vpc.vpc_id
  vnet_id     = module.vpc.vnet_ids.api
  public_ip_id = null            # gateway interne — pas d'IP publique

  global_rate_limit_per_sec = 200
  global_allow_cidrs        = ["10.0.0.0/8", "192.168.0.0/16"]
}
```

## Inputs

| Name | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `name` | string | yes | — | Nom de la gateway (1-100 chars). |
| `region` | string | yes | — | `RNN` / `PAR` / `ABJ`. |
| `plan` | string | no | `"small"` | `small` / `medium` / `large`. |
| `vpc_id` | string | yes | — | UUID du VPC. |
| `vnet_id` | string | yes | — | UUID du VNet hébergeant la VIP. |
| `public_ip_id` | string | no | `null` | UUID de l'IP publique à attacher. `null` = AppGW interne. |
| `force_https` | bool | no | `true` | Redirection HTTP → HTTPS. |
| `hsts_enabled` | bool | no | `false` | Active l'en-tête HSTS. |
| `hsts_max_age` | number | no | `31536000` | `max-age` HSTS en secondes (0-63072000). |
| `global_rate_limit_per_sec` | number | no | `null` | Rate limit global par IP, en req/s. |
| `global_allow_cidrs` | list(string) | no | `[]` | CIDR autorisés globalement. |
| `global_deny_cidrs` | list(string) | no | `[]` | CIDR refusés globalement (priorité sur allow). |
| `trust_proxy_headers` | bool | no | `false` | Accepte `X-Forwarded-For` en entrée. |
| `tags` | list(string) | no | `[]` | Tags (max 60, max 50 chars). |

## Outputs

| Name | Sensitive | Description |
|------|-----------|-------------|
| `id` | no | UUID de la gateway. |
| `name` | no | Nom. |
| `status` | no | `creating` / `active` / `error` / `deleting`. |
| `vip_address` | no | VIP privée dans le VNet. |
| `public_ip_address` | no | IP publique attachée, ou `null`. |
| `plan` | no | Plan effectif. |
| `region` | no | Région. |

## Notes

- Provisioning asynchrone (3-5 min en moyenne). Le provider attend `status=active`.
- Haute disponibilité avec bascule automatique quand `replica_count = 2`.
- Pour les listeners (hostnames + cert ACME) et routes, créer les ressources `ccp_appgw_listener` et utiliser le module `atomic/appgw-route`.
- Pour les pools de backends, utiliser `atomic/appgw-target-group`.
- Le plan détermine routes max / listeners max / rate limit max (voir documentation produit pour les bornes exactes).

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
