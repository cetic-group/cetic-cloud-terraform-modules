variable "name" {
  type        = string
  description = "Nom du cluster (visible dans la console + utilisé comme préfixe DNS du kubeconfig FQDN)."
}

variable "display_name" {
  type        = string
  default     = null
  description = "Display name (libre, pour la console). Default = `name`."
}

variable "region" {
  type = string
  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "Région invalide."
  }
}

variable "vpc_id" {
  type = string
}

variable "tier" {
  type        = string
  default     = "dev"
  description = <<-EOT
    Niveau de service du cluster :

    - `dev` (défaut) : déploiement single-instance du frontal d'exposition de
      l'apiserver — adapté aux environnements de dev / staging / éphémères.
    - `prod` : déploiement actif/passif (deux frontaux + VIP flottante)
      pour la haute-disponibilité du plan de contrôle. Recommandé pour
      les clusters de production.

    Immuable côté provider (`ForceNew`) — changer la valeur recrée le
    cluster.
  EOT

  validation {
    condition     = can(regex("^(dev|prod)$", var.tier))
    error_message = "tier doit être `dev` ou `prod`."
  }
}

variable "vnet_id" {
  type = string
}

variable "k8s_version" {
  type = string
  # Plus de défaut : `v1.31.4` ne correspondait à aucun build et l'API refuse
  # le préfixe « v » à la création d'un cluster (cetic-cloud-platform#2004).
  description = <<-EOT
    Version Kubernetes du **plan de contrôle** du cluster. Sert aussi de version
    par défaut des workers : chaque pool (initial ou additionnel) qui ne fixe pas
    sa propre `k8s_version` hérite de celle-ci. La version d'un pool worker doit
    rester `<=` à celle du plan de contrôle. Format `X.Y.Z` sans « v » (ex.
    `1.34.8`) : versions disponibles via `data.ccp_k8s_templates`.
  EOT
  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.k8s_version))
    error_message = "k8s_version : format X.Y.Z sans « v » (ex. 1.34.8), refusé sinon par l'API à la création du cluster."
  }
}

variable "os_image" {
  type        = string
  default     = null
  description = <<-EOT
    Famille de système d'exploitation des nodes du cluster :
    `flatcar` (défaut), `ubuntu` ou `rocky9`. `null` = laisse la plateforme
    appliquer son défaut (`flatcar`). **Immuable** (`ForceNew`) — changer la
    famille d'OS des nodes recrée le cluster.
  EOT
  validation {
    condition     = var.os_image == null || contains(["flatcar", "ubuntu", "rocky9"], coalesce(var.os_image, "flatcar"))
    error_message = "os_image doit être l'un de : flatcar, ubuntu, rocky9 (ou null pour le défaut plateforme)."
  }
}

variable "os_template_key" {
  type    = string
  default = null
  # `null` → dérivée de `k8s_version` (`kube-v1-34-8` pour `1.34.8`), la forme
  # que l'API écrit et réécrit à chaque montée de version. L'ancien défaut
  # `null` était passé tel quel et faisait échouer le plan (#2004).
  description = <<-EOT
    Clé du template des nodes (cf. `data.ccp_k8s_templates`, attribut `os_key`).
    `null` (recommandé) = dérivée de `k8s_version` : `kube-v1-34-8` pour `1.34.8`.
    ⚠️ Une clé fixée ici doit suivre `k8s_version` : l'API réécrit la clé à
    chaque montée de version, et une clé restée ancienne recréerait le cluster.
  EOT
}

variable "pod_cidr" {
  type    = string
  default = "10.244.0.0/16"
}

variable "service_cidr" {
  type    = string
  default = "10.96.0.0/12"
}

# ─── Initial worker pool (forcé à la création) ────────────────────────────────
variable "initial_pool" {
  description = <<-EOT
    Initial worker pool créé avec le cluster.
    - `name` / `plan` : immutables post-création.
    - `replicas` : mutable.
    - `k8s_version` : version Kubernetes des workers de ce pool. Omis = hérite
      de la version du plan de contrôle (`k8s_version` du cluster). Doit rester
      `<=` à celle du plan de contrôle. Mutable (montée de version rolling).
    - `labels` : map de labels Kubernetes propagés aux nodes du pool. Mutable.
    - `taints` : liste de taints Kubernetes (`{ key, value?, effect }`,
      `effect` ∈ `NoSchedule`|`PreferNoSchedule`|`NoExecute`). Mutable.
    - `min_size` / `max_size` : pour l'autoscaler. Si les deux sont set,
      l'autoscaler du cluster gère ce pool (min_size ≥ 0, max_size > min_size).
      Retirer les deux désactive l'autoscaler (pool figé à `replicas`).
    - `disk_gb` : taille du disque racine des workers de ce pool, en GB. Omis
      (`null`) = taille par défaut du plan (`plan`). Aucun redimensionnement :
      le changer recrée le cluster (pool initial) ou le pool.
  EOT
  type = object({
    name        = optional(string, "default")
    plan        = optional(string, "small")
    replicas    = optional(number, 1)
    k8s_version = optional(string)
    labels      = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
    min_size = optional(number)
    max_size = optional(number)
    disk_gb  = optional(number)
  })
  default = {}

  validation {
    condition     = var.initial_pool.k8s_version == null || can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.initial_pool.k8s_version))
    error_message = "initial_pool.k8s_version : format X.Y.Z sans « v » (l'API retire le « v » et l'état divergerait)."
  }

  validation {
    condition     = (var.initial_pool.min_size == null) == (var.initial_pool.max_size == null)
    error_message = "initial_pool : min_size et max_size doivent être fournis ensemble (ou aucun des deux)."
  }
  validation {
    condition = (
      (var.initial_pool.min_size == null || var.initial_pool.max_size == null)
      ? true
      : (var.initial_pool.min_size >= 0 && var.initial_pool.max_size > var.initial_pool.min_size)
    )
    error_message = "initial_pool : min_size doit être ≥ 0 et max_size > min_size."
  }
  validation {
    condition = alltrue([
      for t in coalesce(var.initial_pool.taints, []) :
      contains(["NoSchedule", "PreferNoSchedule", "NoExecute"], t.effect)
    ])
    error_message = "initial_pool : chaque taint.effect doit être l'un de : NoSchedule, PreferNoSchedule, NoExecute."
  }
}

# ─── Pools additionnels ──────────────────────────────────────────────────────
variable "additional_pools" {
  description = <<-EOT
    Map de worker pools supplémentaires à provisionner après le cluster.
    Clé = nom du pool. Valeur :
    - `plan` : `nano` … `xlarge`
    - `replicas` : count (Required)
    - `k8s_version` : version Kubernetes des workers de ce pool. Omis = hérite
      de la version du plan de contrôle du cluster. Doit rester `<=` à celle du
      plan de contrôle. Mutable (montée de version rolling).
    - `min_size` / `max_size` : pour autoscaler. Si tous les deux sont set,
      l'autoscaler du cluster gère ce pool.
    - `labels` : map de labels Kubernetes propagés aux nodes via
      MachineDeployment.spec.template.metadata.labels.
    - `taints` : liste de taints Kubernetes. Chaque entrée : `{ key, value?, effect }`.
      `effect` ∈ `NoSchedule` | `PreferNoSchedule` | `NoExecute`.
    - `disk_gb` : taille du disque racine des workers de ce pool, en GB. Omis
      (`null`) = taille par défaut du plan. Aucun redimensionnement : le
      changer recrée le pool.
  EOT
  type = map(object({
    plan        = string
    replicas    = number
    k8s_version = optional(string)
    min_size    = optional(number)
    max_size    = optional(number)
    labels      = optional(map(string), {})
    taints = optional(list(object({
      key    = string
      value  = optional(string)
      effect = string
    })), [])
    disk_gb = optional(number)
  }))
  default = {}

  validation {
    condition = alltrue([
      for pool in values(var.additional_pools) :
      alltrue([
        for t in pool.taints :
        contains(["NoSchedule", "PreferNoSchedule", "NoExecute"], t.effect)
      ])
    ])
    error_message = "Chaque taint.effect doit être l'un de : NoSchedule, PreferNoSchedule, NoExecute."
  }

  validation {
    condition = alltrue([
      for pool in values(var.additional_pools) :
      pool.k8s_version == null || can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", pool.k8s_version))
    ])
    error_message = "additional_pools[*].k8s_version : format X.Y.Z sans « v » (l'API retire le « v » et l'état divergerait)."
  }
}

# ─── Autoscaler global ───────────────────────────────────────────────────────
variable "autoscaler_scale_down_delay_after_add" {
  type    = string
  default = "10m"
}

variable "autoscaler_scale_down_unneeded_time" {
  type    = string
  default = "10m"
}

# ─── Ingress controller ──────────────────────────────────────────────────────
variable "ingress_controller_enabled" {
  type    = bool
  default = true
}

variable "ingress_controller_scope" {
  type        = string
  default     = "external"
  description = "`external` (IP publique) ou `internal` (VIP privée VNet). ⚠️ Défaut du module `external`, celui de la ressource `ccp_k8s_cluster` est `internal` : le module garde `external` pour ne pas basculer les clusters existants (le changement s'applique sans recréation)."
  validation {
    condition     = contains(["external", "internal"], var.ingress_controller_scope)
    error_message = "ingress_controller_scope doit être external ou internal."
  }
}

variable "ingress_controller_class" {
  type        = string
  default     = "incluster"
  description = "`incluster` (Cilium L2 announce, HA) ou `managed` (LB dédié géré par la plateforme)."
  validation {
    condition     = contains(["incluster", "managed"], var.ingress_controller_class)
    error_message = "ingress_controller_class doit être incluster ou managed."
  }
}

variable "ingress_public_ip_id" {
  type        = string
  default     = null
  description = "UUID d'une IP publique pré-allouée pour l'ingress (mode external). `null` = auto-allouée."
}

variable "ingress_internal_ip" {
  type        = string
  default     = null
  description = "IP privée fixe pour l'ingress (mode internal). `null` = auto-allouée dans le VNet."
}

# ─── Apiserver exposure ──────────────────────────────────────────────────────
variable "apiserver_public_ip_id" {
  type        = string
  default     = null
  description = <<-EOT
    UUID d'une IP publique pour l'apiserver (kubeconfig public). **Mutable**
    (provider >= 3.0.0) : définir l'UUID attache l'IP, `null` la détache,
    changer la valeur la remplace — le tout **sans recréer le cluster**, à la
    création comme après coup. L'IP doit être dans la même région, de type
    routé, et le VNet du cluster doit avoir SNAT activé.
  EOT
}

variable "apiserver_internal_ip" {
  type        = string
  default     = null
  description = "IP privée fixe pour l'apiserver. `null` = auto."
}

variable "tags" {
  type    = list(string)
  default = []
}
