# Compatibilité des modules AppGW avec la refonte #2054

Cette matrice concerne les modules AppGW publiés avant l'intégration complète de
[la refonte #2054](https://github.com/cetic-group/cetic-cloud-platform/issues/2054).
Elle décrit les changements visibles dans la console et leur effet sur les
configurations Terraform existantes. Les nouvelles PR du provider ne deviennent
utilisables dans les modules qu'après fusion, publication d'une version du
provider et ajustement de la contrainte de version des modules.

| Fonction | Modules actuels | Évolution #2054 | Compatibilité et action | Tests existants / manque |
| --- | --- | --- | --- | --- |
| Passerelle et cache global | `cache_enabled = false` par défaut ; capacité fixée par le plan | Cache global toujours facultatif et payant | Aucun cache activé par migration. Conserver le défaut si le coût n'est pas souhaité. | `atomic/application-gateway/tests/basic.tftest.hcl` : `creates_with_minimal`, `cache_configuration`, `cache_profile_is_read_from_provider`. |
| Cache des routes | `cache_mode = "off"` par défaut dans `atomic/appgw-route` et `exposure/web-app-with-appgw` | Le domaine a désormais un choix distinct `null` / `false` / `true` | Une route à `off` reste sans cache même si le cache global et celui du domaine sont activés. Les règles historiques restent appliquées ; ne pas convertir implicitement `off` en héritage. | `atomic/appgw-route/tests/basic.tftest.hcl` : `creates_default_route`, `cache_configuration`. |
| Cache du domaine | Aucun input ni output dans les modules | Le provider [#123](https://github.com/cetic-group/terraform-provider-ccp/pull/123) propose une lecture seule tri-état | Configurer dans la console ou via l'API/CLI compatible après déploiement. Le provider ne peut pas encore définir la valeur au POST initial ni la rétablir à `null`, donc aucun input module n'est ajouté. | Aucun test module : aucun cycle de vie HCL disponible. La lecture tri-état est testée dans la PR provider #123. |
| Health check du Target group | Toujours activé ; `health_check` règle la sonde | L'API [#2055](https://github.com/cetic-group/cetic-cloud-platform/pull/2055) et le provider [#122](https://github.com/cetic-group/terraform-provider-ccp/pull/122) permettent une désactivation explicite | Les configurations existantes conservent leur sonde. Le module n'expose pas encore `hc_enabled` ; attendre une version de module dépendant d'un provider publié avec ce champ pour gérer la désactivation en HCL. | `atomic/appgw-target-group/tests/basic.tftest.hcl` : `creates_with_defaults`. Aucun test de désactivation au niveau module. |
| Méthode/fournisseur/secret ACME | `acme_challenge`, `acme_dns_provider` et `acme_dns_credentials` forcent un remplacement | L'API [#2061](https://github.com/cetic-group/cetic-cloud-platform/pull/2061) prépare une rotation différée, désactivée par défaut | Terraform garde `RequiresReplace` : vérifier le plan avant l'apply. Dans le module composé, ces trois valeurs sont communes à **tous** les hostnames ; leur changement peut remplacer tous les listeners. Une rotation effectuée hors Terraform laisse le HCL à réconcilier. | `atomic/appgw-listener/tests/basic.tftest.hcl` : `creates_without_acme`, `creates_with_http01`, `creates_with_dns01`. Aucun test de rotation plan/import du module. |
| Haute disponibilité | `replica_count` 1 ou 2 ; changement par remplacement dans le provider actuel | Transition en place en cours de livraison | Ne pas rendre cette variable mutable dans les modules avant la disponibilité de l'API et du provider correspondants. | `atomic/application-gateway/tests/basic.tftest.hcl` et `exposure/web-app-with-appgw/tests/basic.tftest.hcl` : `replica_count_single`, `replica_count_default_ha`. Aucun test de transition en place. |
| Règles de sécurité | `l4_policy`, `l7_policy`, `client_ip_policy` et règles de route déjà prises en charge | Niveaux passerelle, domaine et route explicités dans la console | Les politiques HCL existantes restent en place. Les règles nouvelles absentes du schéma du provider ne sont pas déclarées comme actives par les modules. | `exposure/web-app-with-appgw/tests/basic.tftest.hcl` : `policies_on_all_scopes` ; tests `typed_security_policy` des modules atomiques. |

Cette matrice est informative : elle ne change aucun état Terraform, aucune
ressource distante ni la contrainte provider `>= 7.5.0` des modules existants.
Une prochaine livraison pourra ajouter les inputs/outputs du Health check et du
cache domaine après publication des contrats provider et tests de plan/import.
