# Module `managed/k8s-cluster`

Wrapper riche autour de `ccp_k8s_cluster` + `ccp_k8s_node_pool`. Crée un cluster Kubernetes managé (CCKS) avec son initial pool et N pools additionnels via une map (`for_each`).

## Exemple

```hcl
module "platform" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/managed/k8s-cluster?ref=v0.21.0"

  name        = "platform-prod"
  region      = "RNN"
  vpc_id      = module.vpc.vpc_id
  vnet_id     = module.vpc.vnet_ids.workers
  plan        = "standard" # starter / standard / pro (provider >= 7.6.0)
  k8s_version = "1.34.8"   # version souhaitée du control plane (X.Y.Z, sans « v »)
  os_image    = "ubuntu"   # famille d'OS des nodes (flatcar défaut / ubuntu / rocky9)

  # Mises à jour automatiques (optionnel, null = réglages plateforme laissés tels quels).
  maintenance = {
    auto_patch   = true
    auto_mineure = false
    fenetre = {
      jours        = [6, 7] # samedi, dimanche
      heure_debut  = "02:00"
      duree_heures = 6
      fuseau       = "Europe/Paris"
    }
    dates_gel = [{ debut = "2026-12-20", fin = "2027-01-03" }]
  }

  # SSO OIDC de l'apiserver (optionnel, null = pas de SSO).
  oidc = {
    issuer_url = "https://sso.example.com/realms/acme"
    client_id  = "kubernetes"
  }

  initial_pool = {
    name     = "default"
    plan     = "small"
    replicas = 2
    labels   = { workload = "app" }
    # Autoscaler sur le pool initial (optionnel) : min_size + max_size ensemble.
    min_size = 2
    max_size = 4
    # k8s_version omis → workers du pool initial à la version du control plane, à la création seulement.
    disk_gb = 100 # défaut du plan `small` dépassé pour ce pool
  }

  additional_pools = {
    cpu_pool = {
      plan     = "medium"
      replicas = 3
      min_size = 3
      max_size = 10
      labels   = { workload = "cpu" }
      # Workers à une version antérieure au control plane (montée progressive).
      k8s_version = "1.33.2"
      disk_gb     = 150 # non redimensionnable : le changer recrée le pool
    }
    gpu_pool = {
      plan     = "xlarge"
      replicas = 1
      min_size = 0
      max_size = 4
      labels   = { workload = "gpu", nvidia = "true" }
      taints = [
        {
          key    = "nvidia.com/gpu"
          value  = "present"
          effect = "NoSchedule"
        },
      ]
    }
  }

  ingress_controller_enabled = true
  ingress_controller_scope   = "external"
  ingress_controller_class   = "incluster"

  apiserver_public_ip_id = module.lb_apiserver_ip.id
  tags                   = ["env:prod"]
}

output "kubeconfig_url" {
  value = module.platform.api_endpoint
}
```

## Inputs

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | string | required | Nom (préfixe DNS du kubeconfig FQDN). |
| `display_name` | string | `name` | Display name. |
| `region` | string | required | `RNN`/`PAR`/`ABJ`. |
| `plan` | string | `null` | Plan du control plane : `starter` (frontal unique, sans HA, ≤ 10 nodes), `standard` (HA actif/passif + VIP flottante, 2 réplicas, ≤ 50 nodes), `pro` (3 réplicas, ≤ 150 nodes). `standard` ↔ `pro` en place ; `starter` ↔ payant **recrée le cluster**. `null` = découle de `tier` (sinon `starter`) à la création, plan courant conservé ensuite. |
| `tier` | string | `null` | **Déprécié** → `plan`. `dev` = `starter`, `prod` = `standard` (ou `pro` courant). Transmis seulement s'il est fourni ; contradictoire avec `plan` → refusé. |
| `vpc_id` / `vnet_id` | string | required | Réseau cible. |
| `k8s_version` | string | — (requis) | Version Kubernetes souhaitée du **control plane**, format `X.Y.Z` sans « v » (cf. `data.ccp_k8s_templates`). La monter ne monte que le control plane ; un pool sans `k8s_version` propre en prend la version à la création seulement. |
| `os_image` | string | `null` | Famille d'OS des nodes : `flatcar` (défaut) / `ubuntu` / `rocky9`. `null` = défaut plateforme. **Immuable** (recrée le cluster). |
| `os_template_key` | string | `null` | Lue **à la création seulement** : `null` = dérivée de `k8s_version` (`kube-v1-34-8` pour `1.34.8`). Le module ignore ensuite tout écart (`ignore_changes`), car l'API réécrit la clé à chaque montée de version : la changer, ou retirer une clé déjà appliquée, n'a aucun effet sur un cluster existant. |
| `pod_cidr` | string | `"10.244.0.0/16"` | |
| `service_cidr` | string | `"10.96.0.0/12"` | |
| `initial_pool` | object({name, plan, replicas, k8s_version?, labels?, taints?, min_size?, max_size?, disk_gb?}) | `{}` | Pool initial. `name`/`plan`/`disk_gb` immutables (les changer recrée le cluster) ; `replicas`/`k8s_version`/`labels`/`taints`/`min_size`/`max_size` mutables. `k8s_version` = version worker du pool (omis = version du control plane à la création seulement, ensuite la monter ici ; doit rester `<=`). `labels` = map ; `taints` = liste de `{ key, value?, effect }` ; `min_size`+`max_size` (ensemble) activent l'autoscaler. `disk_gb` = taille du disque racine des workers (omis = défaut du plan ; non redimensionnable : la changer **recrée le cluster**). |
| `additional_pools` | map(object) | `{}` | Pools additionnels via for_each. Chaque objet : `plan`, `replicas`, `k8s_version?`, `min_size?`, `max_size?`, `labels?`, `taints?`, `disk_gb?`. `k8s_version` = version worker (omis = version du control plane à la création seulement, ensuite la monter ici ; doit rester `<=` ; mutable, montée rolling). `disk_gb` = taille du disque racine des workers (omis = défaut du plan ; non redimensionnable : la changer **recrée le pool**). |
| `autoscaler_scale_down_delay_after_add` | string | `"10m"` | |
| `autoscaler_scale_down_unneeded_time` | string | `"10m"` | |
| `ingress_controller_enabled` | bool | `true` | |
| `ingress_controller_scope` | string | `"external"` | `external` / `internal`. |
| `ingress_controller_class` | string | `"incluster"` | `incluster` (Cilium L2) / `managed` (LB dédié). |
| `ingress_public_ip_id` | string | `null` | IP pré-allouée. |
| `ingress_internal_ip` | string | `null` | IP privée fixe. |
| `apiserver_public_ip_id` | string | `null` | IP publique apiserver (kubeconfig public). **Mutable** (provider ≥ 3.0.0) — attach/détach/rotate sans recréer le cluster. |
| `apiserver_internal_ip` | string | `null` | IP privée fixe apiserver. |
| `maintenance` | object({auto_patch?, auto_mineure?, auto_majeure?, fenetre?, dates_gel?}) | `null` | Mises à jour automatiques et fenêtre de maintenance. `null` = non géré (réglages plateforme / console relus et laissés). Seuls les champs écrits sont gérés. `fenetre` = `{ jours (1-7), heure_debut "HH:MM", duree_heures (4-24), fuseau IANA }` ; `dates_gel` = liste (≤ 12) de `{ debut, fin }` `YYYY-MM-DD`. |
| `oidc` | object({issuer_url, client_id, username_claim?, username_prefix?, groups_claim?, groups_prefix?, extra_scopes?, ca_pem?}) | `null` | SSO OIDC de l'apiserver. `null` = pas de SSO ; retirer le bloc supprime le SSO. Un changement redémarre l'apiserver. Champs omis = défauts du provider (`email`, `oidc:`, `groups`, `oidc:`, aucun scope). |
| `timeouts` | object({create?, update?, delete?}) | `null` | Délais d'attente du provider (durées Go, ex. `1h30m`), passés au bloc `timeouts` du cluster. Défauts provider : `create` 15m, `update` 30m à 90m selon l'attente (upgrade du control plane 45m, du pool initial 90m), `delete` 20m. |
| `tags` | list(string) | `[]` | |

## Outputs

| Name | Description |
|------|-------------|
| `id` | UUID. |
| `name` | |
| `os_image` | Famille d'OS effective des nodes (`flatcar`/`ubuntu`/`rocky9`). |
| `k8s_version` | Version Kubernetes souhaitée du control plane. |
| `current_k8s_version` | Version réellement exécutée par le control plane (peut dépasser `k8s_version` après un patch automatique). |
| `api_endpoint` | host:port apiserver (kubeconfig). |
| `apiserver_internal_ip` / `apiserver_public_ip_address` | |
| `ingress_internal_ip` / `ingress_public_ip_address` | |
| `additional_pool_ids` | Map UUID des pools additionnels. |
| `additional_pool_k8s_versions` | Map nom de pool → version Kubernetes worker effective. |
| `additional_pool_disk_gb` | Map nom de pool → taille de disque racine effective (GB). |
| `status` | |
| `plan` | Plan effectif (`starter` / `standard` / `pro`). |
| `etcd_volume_gb` | Volume etcd effectif (GiB), jamais réduit. |
| `node_ip_block_size` | Taille du bloc d'IP des nodes dans le VNet (`null` tant qu'il n'est pas alloué). |
| `tier` | **Déprécié** → `plan`. `dev` pour `starter`, `prod` pour `standard`/`pro`. |
| `proxy_vip_vnet` | VIP flottante VNet partagée par les deux frontaux (plans `standard`/`pro`, sinon `null`). |

## Notes

- **Provider `>= 7.6.0`** (cetic-cloud-platform#2143) : `plan`, `maintenance`,
  `oidc` et les outputs `plan` / `etcd_volume_gb` / `node_ip_block_size` /
  `current_k8s_version` l'exigent.
- **`plan`** : `starter` ↔ `standard`/`pro` recrée le cluster (le frontal
  d'exposition change de topologie) ; `standard` ↔ `pro` se fait en place.
  Choisir un plan payant dès la création pour les charges critiques.
- **`tier` déprécié** : une configuration qui ne renseigne que `tier` garde son
  comportement (`dev` → `starter`, `prod` → `standard`). Migrer en remplaçant
  `tier = "dev"` par `plan = "starter"` et `tier = "prod"` par
  `plan = "standard"` (ou `"pro"` si le cluster l'est déjà) : aucun changement
  planifié. Sans `plan` ni `tier`, un cluster existant garde son plan courant.
- **Montée de version** (provider `>= 7.6.0`) : monter `k8s_version` met à jour
  le **control plane seul** ; les pools se montent ensuite via leur propre
  `k8s_version` (un node à la fois). `k8s_version` est la version souhaitée,
  jamais redescendue : un patch automatique ne crée pas de diff.
- **`initial_pool`** : `name`/`plan`/`disk_gb` sont immutables (les changer recrée le cluster) ; `replicas`, `labels`, `taints`, `min_size`/`max_size` sont mutables in-place (parité avec `additional_pools`). Définir `min_size` **et** `max_size` active l'autoscaler ; les retirer le désactive (pool figé à `replicas`). `labels`/`taints` nécessitent le provider `>= 3.2.0` ; l'autoscaler `>= 3.1.1`.
- **`os_image` immutable** : la famille d'OS des nodes (`flatcar`/`ubuntu`/`rocky9`) est figée à la création — la changer recrée le cluster. Laisser `null` applique le défaut plateforme (`flatcar`).
- **Versions Kubernetes par pool** : `k8s_version` au niveau du cluster fixe le **control plane** et sert de version des workers **à la création seulement**. Chaque pool (initial ou additionnel) peut fixer sa propre `k8s_version` ; un pool qui l'omet ne suit **pas** les montées du control plane (provider `>= 7.6.0`). La version d'un pool worker doit rester `<=` à celle du control plane ; modifier `k8s_version` d'un pool déclenche une montée de version rolling (un node à la fois, pas de recréation du pool). Montée : control plane puis pools — possible dans le même apply (le provider monte le control plane, attend, puis les pools), ou en plusieurs fois pour une montée progressive.
- **Disque des workers par pool** : `disk_gb` (initial ou additionnel) fixe la taille du disque racine des workers de ce pool, indépendamment du disque par défaut du `plan`. Omis = défaut du plan. **Non redimensionnable** : la plateforme n'expose aucun redimensionnement du disque d'un pool ; changer la valeur, à la hausse comme à la baisse, **recrée le pool** (pool additionnel) ou **le cluster** (`initial_pool`).
- **Ingress en mode `incluster`** : HA inter-worker via Cilium L2 announce, failover ~22s.
- **Ingress en mode `managed`** : LB dédié devant l'ingress controller — meilleur pour des bursts de connexions externes mais coûte un LB additionnel.
- Le **kubeconfig** est récupérable via `cetic k8s kubeconfig <id>` (CLI) ou `GET /v1/k8s/clusters/{id}/kubeconfig`. Pas exposé par le provider TF (matière à être ajouté en datasource v0.9+).
