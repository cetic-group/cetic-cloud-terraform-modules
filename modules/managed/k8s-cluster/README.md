# Module `managed/k8s-cluster`

Wrapper riche autour de `ccp_k8s_cluster` + `ccp_k8s_node_pool`. Crée un cluster Kubernetes managé (CCKS) avec son initial pool et N pools additionnels via une map (`for_each`).

## Exemple

```hcl
module "platform" {
  source = "github.com/cetic-group/cetic-cloud-terraform-modules//modules/managed/k8s-cluster?ref=v0.2.0"

  name        = "platform-prod"
  region      = "RNN"
  vpc_id      = module.vpc.vpc_id
  vnet_id     = module.vpc.vnet_ids.workers
  k8s_version = "v1.31.4"

  initial_pool = {
    name     = "default"
    plan     = "small"
    replicas = 2
  }

  additional_pools = {
    cpu_pool = {
      plan     = "medium"
      replicas = 3
      min_size = 3
      max_size = 10
      labels   = { workload = "cpu" }
    }
    gpu_pool = {
      plan     = "xlarge"
      replicas = 1
      min_size = 0
      max_size = 4
      labels   = { workload = "gpu", nvidia = "true" }
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
| `tier` | string | `"dev"` | `dev` (single) ou `prod` (HA actif/passif + VIP flottante). Immuable. |
| `vpc_id` / `vnet_id` | string | required | Réseau cible. |
| `k8s_version` | string | `"v1.31.4"` | Version control plane + initial pool. |
| `os_template_key` | string | `null` | Cf. `data.ccp_k8s_templates`. |
| `pod_cidr` | string | `"10.244.0.0/16"` | |
| `service_cidr` | string | `"10.96.0.0/12"` | |
| `initial_pool` | object({name, plan, replicas}) | `{}` | Pool initial (immutable). |
| `additional_pools` | map(object) | `{}` | Pools additionnels via for_each. |
| `autoscaler_scale_down_delay_after_add` | string | `"10m"` | |
| `autoscaler_scale_down_unneeded_time` | string | `"10m"` | |
| `ingress_controller_enabled` | bool | `true` | |
| `ingress_controller_scope` | string | `"external"` | `external` / `internal`. |
| `ingress_controller_class` | string | `"incluster"` | `incluster` (Cilium L2) / `managed` (LB dédié). |
| `ingress_public_ip_id` | string | `null` | IP pré-allouée. |
| `ingress_internal_ip` | string | `null` | IP privée fixe. |
| `apiserver_public_ip_id` | string | `null` | Si fourni, kubeconfig public. |
| `apiserver_internal_ip` | string | `null` | IP privée fixe apiserver. |
| `tags` | list(string) | `[]` | |

## Outputs

| Name | Description |
|------|-------------|
| `id` | UUID. |
| `name` | |
| `api_endpoint` | host:port apiserver (kubeconfig). |
| `apiserver_internal_ip` / `apiserver_public_ip_address` | |
| `ingress_internal_ip` / `ingress_public_ip_address` | |
| `additional_pool_ids` | Map UUID des pools additionnels. |
| `status` | |
| `tier` | Niveau de service effectif (`dev` / `prod`). |
| `proxy_secondary_vmid` | VMID du frontal secondaire (tier `prod`, sinon `null`). |
| `proxy_secondary_node` | Hôte du frontal secondaire (tier `prod`, sinon `null`). |
| `proxy_vip_vnet` | VIP flottante VNet partagée par les deux frontaux (tier `prod`, sinon `null`). |

## Notes

- **`tier` immutable** : `dev` → `prod` (ou l'inverse) recrée le cluster. Choisir
  `prod` dès la création pour les charges critiques afin d'activer le frontal
  d'exposition redondé (deux instances actives/passives + VIP flottante VNet).
- **`initial_pool` immutable** : pour le supprimer ou le redimensionner différemment, recréer le cluster.
- **Pools additionnels avec `min_size`/`max_size`** : le cluster autoscaler propage automatiquement les annotations sur la MachineDeployment et scale up/down selon la charge.
- **Ingress en mode `incluster`** : HA inter-worker via Cilium L2 announce, failover ~22s.
- **Ingress en mode `managed`** : LB dédié devant l'ingress controller — meilleur pour des bursts de connexions externes mais coûte un LB additionnel.
- Le **kubeconfig** est récupérable via `cetic k8s kubeconfig <id>` (CLI) ou `GET /v1/k8s/clusters/{id}/kubeconfig`. Pas exposé par le provider TF (matière à être ajouté en datasource v0.9+).
