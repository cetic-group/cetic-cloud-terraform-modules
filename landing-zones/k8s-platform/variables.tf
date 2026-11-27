variable "org_prefix" {
  type        = string
  description = "Préfixe métier (ex `acme`)."
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}[a-z0-9]$", var.org_prefix))
    error_message = "org_prefix doit matcher [a-z][a-z0-9-]+[a-z0-9], 3-32 chars."
  }
}

variable "region" {
  type = string
  validation {
    condition     = contains(["RNN", "PAR", "ABJ"], var.region)
    error_message = "Région invalide."
  }
}

# ─── K8s ──────────────────────────────────────────────────────────────────────
variable "k8s_version" {
  type        = string
  description = <<-EOT
    Version Kubernetes souhaitée du control plane du cluster CCKS, format
    X.Y.Z sans « v » (cf. `data.ccp_k8s_templates`). Depuis le provider 7.6.0,
    la monter ne monte que le control plane : les pools gardent leur version
    (cf. `initial_pool_k8s_version` et `additional_pools[*].k8s_version`).
  EOT
}

variable "os_template_key" {
  type        = string
  default     = null
  description = "Clé du template des nodes (cf. `data.ccp_k8s_templates`). Lue à la création seulement (le module ignore ensuite tout écart). `null` = dérivée de `k8s_version` par le module."
}

variable "initial_pool_k8s_version" {
  type        = string
  default     = null
  description = <<-EOT
    Version Kubernetes des workers du pool initial, passée à
    `initial_pool.k8s_version`. `null` (défaut) = version du control plane à la
    création seulement : le pool ne suit pas les montées de `k8s_version`. Pour
    monter le cluster : monter `k8s_version` (control plane) puis cette
    variable — possible dans le même apply. Doit rester `<=` à `k8s_version`.
  EOT
}

variable "os_image" {
  type        = string
  default     = null
  description = <<-EOT
    Famille d'OS des nodes du cluster (`flatcar` défaut / `ubuntu` / `rocky9`).
    `null` = défaut plateforme (`flatcar`). Immuable — recrée le cluster.
  EOT
  validation {
    condition     = var.os_image == null || contains(["flatcar", "ubuntu", "rocky9"], coalesce(var.os_image, "flatcar"))
    error_message = "os_image doit être l'un de : flatcar, ubuntu, rocky9 (ou null)."
  }
}

variable "k8s_plan" {
  type        = string
  default     = null
  description = <<-EOT
    Plan du control plane du cluster CCKS — passé tel quel au module
    `managed/k8s-cluster` : `starter` (frontal unique, sans HA), `standard`
    (frontaux actif/passif + VIP flottante VNet) ou `pro` (3 réplicas).
    `standard` ↔ `pro` en place ; `starter` ↔ payant recrée le cluster.
    `null` (défaut) : découle de `k8s_tier` s'il est fourni, sinon `starter` à
    la création ; plan courant conservé ensuite.
  EOT

  validation {
    condition     = var.k8s_plan == null || contains(["starter", "standard", "pro"], coalesce(var.k8s_plan, "starter"))
    error_message = "k8s_plan doit être `starter`, `standard` ou `pro` (ou null)."
  }
}

variable "k8s_tier" {
  type        = string
  default     = null
  description = <<-EOT
    **Déprécié** — utiliser `k8s_plan`. `dev` = `starter`, `prod` = plan payant
    (`standard`). Passé au module seulement s'il est fourni ; contradictoire
    avec `k8s_plan` → refusé. `null` (défaut) : non transmis (un cluster créé
    avec l'ancien défaut `dev` reste `starter`).
  EOT

  validation {
    condition     = var.k8s_tier == null || contains(["dev", "prod"], coalesce(var.k8s_tier, "dev"))
    error_message = "k8s_tier doit être `dev` ou `prod` (ou null). Préférer `k8s_plan`."
  }
}

variable "k8s_maintenance" {
  description = "Mises à jour automatiques et fenêtre de maintenance du cluster — cf. la variable `maintenance` de `managed/k8s-cluster`. `null` (défaut) = non géré."
  type = object({
    auto_patch   = optional(bool)
    auto_mineure = optional(bool)
    auto_majeure = optional(bool)
    fenetre = optional(object({
      jours        = list(number)
      heure_debut  = string
      duree_heures = number
      fuseau       = string
    }))
    dates_gel = optional(list(object({
      debut = string
      fin   = string
    })))
  })
  default = null
}

variable "k8s_oidc" {
  description = "SSO OIDC de l'apiserver — cf. la variable `oidc` de `managed/k8s-cluster`. `null` (défaut) = pas de SSO."
  type = object({
    issuer_url      = string
    client_id       = string
    username_claim  = optional(string)
    username_prefix = optional(string)
    groups_claim    = optional(string)
    groups_prefix   = optional(string)
    extra_scopes    = optional(list(string))
    ca_pem          = optional(string)
  })
  default = null
}

variable "initial_pool_replicas" {
  type        = number
  default     = 2
  description = "Replicas du pool initial du cluster K8s."
}

variable "initial_pool_plan" {
  type    = string
  default = "small"
}

variable "additional_pools" {
  description = "Pools additionnels passés au module managed/k8s-cluster (cf. son README pour le schéma)."
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
}

variable "expose_apiserver_publicly" {
  type        = bool
  default     = false
  description = "Si `true`, attache une IP publique à l'apiserver (kubeconfig public)."
}

variable "ingress_scope" {
  type        = string
  default     = "external"
  description = "`external` (IP publique) ou `internal`."
}

# ─── Database optionnelle ─────────────────────────────────────────────────────
variable "enable_database" {
  type        = bool
  default     = true
  description = "Provisionne une instance PostgreSQL managée dans le VNet `data` à côté du cluster K8s."
}

variable "db_plan" {
  type    = string
  default = "small"
}

variable "db_replicas" {
  type    = number
  default = 1
  validation {
    condition     = contains([1, 3], var.db_replicas)
    error_message = "db_replicas doit être 1 ou 3."
  }
}

variable "db_storage_gb" {
  type    = number
  default = 20
}

variable "tags_extra" {
  type    = list(string)
  default = []
}

variable "k8s_timeouts" {
  description = "Délais d'attente du provider pour le cluster (`create`, `update`, `delete`, durées Go) — cf. la variable `timeouts` de `managed/k8s-cluster`. `null` (défaut) = défauts du provider."
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null
}
