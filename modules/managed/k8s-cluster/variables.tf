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

variable "plan" {
  type        = string
  default     = null
  description = <<-EOT
    Plan du control plane du cluster (provider >= 7.6.0) :

    - `starter` : gratuit, frontal d'exposition de l'apiserver unique, sans
      haute disponibilité, jusqu'à 10 nodes — dev / staging / éphémère.
    - `standard` : paire de frontaux actif/passif + VIP flottante VNet,
      2 réplicas du control plane, jusqu'à 50 nodes.
    - `pro` : 3 réplicas du control plane, jusqu'à 150 nodes.

    `standard` ↔ `pro` se change en place ; `starter` ↔ un plan payant
    **recrée le cluster** (le frontal change de topologie).

    `null` (défaut) : à la création, le plan découle de `tier` s'il est fourni
    (`dev` → `starter`, `prod` → `standard`), sinon `starter` ; sur un cluster
    existant, le plan courant est conservé (y compris un changement fait depuis
    la console).
  EOT

  validation {
    condition     = var.plan == null || contains(["starter", "standard", "pro"], coalesce(var.plan, "starter"))
    error_message = "plan doit être `starter`, `standard` ou `pro` (ou null)."
  }
}

variable "tier" {
  type        = string
  default     = null
  description = <<-EOT
    **Déprécié** — utiliser `plan`. Conservé pour les configurations
    existantes : `dev` équivaut à `plan = "starter"`, `prod` à un plan payant
    (`standard`, ou `pro` si le cluster l'est déjà). Transmis au provider
    uniquement s'il est fourni (le provider émet alors un avertissement de
    dépréciation). Renseigner `plan` et `tier` avec des topologies différentes
    (`starter` + `prod`, ou `standard`/`pro` + `dev`) est refusé.

    `null` (défaut) : non transmis. Un cluster créé sans `tier` (ancien défaut
    `dev`) reste `starter` ; changer `starter` ↔ `prod` recrée le cluster.
  EOT

  validation {
    condition     = var.tier == null || contains(["dev", "prod"], coalesce(var.tier, "dev"))
    error_message = "tier doit être `dev` ou `prod` (ou null). Préférer `plan`."
  }
}

variable "vnet_id" {
  type = string
}

variable "k8s_version" {
  type        = string
  default     = "v1.31.4"
  description = <<-EOT
    Version Kubernetes du **control plane** du cluster. Un pool (initial ou
    additionnel) créé sans sa propre `k8s_version` prend cette version **à la
    création seulement**. La version d'un pool worker doit rester `<=` à celle
    du control plane.

    Version **souhaitée** (provider >= 7.6.0) : la monter met à jour le
    control plane **seul** ; les pools ne suivent pas, il faut monter ensuite
    la `k8s_version` de chaque pool (possible dans le même apply : le provider
    monte le control plane puis les pools). Elle n'est jamais redescendue — un
    patch automatique au-delà ne crée pas de diff. La version effective est
    l'output `current_k8s_version`.
  EOT
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
  type        = string
  default     = null
  description = "Clé du template OS pour les nodes workers (cf. `data.ccp_k8s_templates`). `null` = template par défaut de la région."
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
    - `k8s_version` : version Kubernetes des workers de ce pool. Omis = prend
      la version du control plane (`k8s_version` du cluster) à la création
      seulement ; ensuite, monter la `k8s_version` du pool. Doit rester `<=` à
      celle du control plane. Mutable (montée de version rolling).
    - `labels` : map de labels Kubernetes propagés aux nodes du pool. Mutable.
    - `taints` : liste de taints Kubernetes (`{ key, value?, effect }`,
      `effect` ∈ `NoSchedule`|`PreferNoSchedule`|`NoExecute`). Mutable.
    - `min_size` / `max_size` : pour l'autoscaler. Si les deux sont set,
      l'autoscaler du cluster gère ce pool (min_size ≥ 0, max_size > min_size).
      Retirer les deux désactive l'autoscaler (pool figé à `replicas`).
    - `disk_gb` : taille du disque racine des workers de ce pool, en GB. Omis
      (`null`) = taille par défaut du plan (`plan`). Grow-only.
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
    - `k8s_version` : version Kubernetes des workers de ce pool. Omis = prend
      la version du control plane à la création seulement ; ensuite, monter la
      `k8s_version` du pool. Doit rester `<=` à celle du control plane.
      Mutable (montée de version rolling).
    - `min_size` / `max_size` : pour autoscaler. Si tous les deux sont set,
      l'autoscaler du cluster gère ce pool.
    - `labels` : map de labels Kubernetes propagés aux nodes via
      MachineDeployment.spec.template.metadata.labels.
    - `taints` : liste de taints Kubernetes. Chaque entrée : `{ key, value?, effect }`.
      `effect` ∈ `NoSchedule` | `PreferNoSchedule` | `NoExecute`.
    - `disk_gb` : taille du disque racine des workers de ce pool, en GB. Omis
      (`null`) = taille par défaut du plan. Grow-only.
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
  description = "`external` (IP publique) ou `internal` (VIP privée VNet)."
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

# ─── Mises à jour automatiques et fenêtre de maintenance ─────────────────────
variable "maintenance" {
  description = <<-EOT
    Mises à jour Kubernetes automatiques du cluster et leur fenêtre de
    maintenance (provider >= 7.6.0). `null` (défaut) = non géré : les réglages
    de la plateforme (patchs automatiques activés, mineures et majeures
    désactivées, ou ce qui a été posé depuis la console) sont relus et laissés
    tels quels. Renseigné, seuls les champs écrits sont gérés ; repasser à
    `null` arrête la gestion sans rien réinitialiser.

    - `auto_patch` / `auto_mineure` / `auto_majeure` : appliquer
      automatiquement, dans la fenêtre, les patchs de la mineure courante, la
      mineure suivante, la majeure suivante.
    - `fenetre` : bloc entier `{ jours, heure_debut, duree_heures, fuseau }` —
      `jours` = jours ISO 1 (lundi) à 7 (dimanche), `heure_debut` = `HH:MM`
      locale, `duree_heures` de 4 à 24, `fuseau` IANA (ex. `Europe/Paris`).
    - `dates_gel` : périodes de gel (au plus 12, 31 jours chacune, bornes
      incluses, `YYYY-MM-DD`) pendant lesquelles aucune mise à jour
      automatique ne démarre.
  EOT
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

  validation {
    condition = try(var.maintenance.fenetre, null) == null || try(
      length(var.maintenance.fenetre.jours) >= 1 && length(var.maintenance.fenetre.jours) <= 7
      && alltrue([for j in var.maintenance.fenetre.jours : j >= 1 && j <= 7 && floor(j) == j])
      && can(regex("^([01][0-9]|2[0-3]):[0-5][0-9]$", var.maintenance.fenetre.heure_debut))
      && var.maintenance.fenetre.duree_heures >= 4 && var.maintenance.fenetre.duree_heures <= 24
      && floor(var.maintenance.fenetre.duree_heures) == var.maintenance.fenetre.duree_heures
      && length(var.maintenance.fenetre.fuseau) >= 1 && length(var.maintenance.fenetre.fuseau) <= 64,
      false
    )
    # Mêmes bornes que le provider v7.6.0 (maintenance.go).
    error_message = "maintenance.fenetre : 1 à 7 jours entre 1 et 7, heure_debut au format HH:MM, duree_heures entière de 4 à 24, fuseau de 1 à 64 caractères."
  }
  validation {
    condition = try(var.maintenance.dates_gel, null) == null || try(
      length(var.maintenance.dates_gel) <= 12 && alltrue([
        for g in var.maintenance.dates_gel :
        can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", g.debut)) && can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", g.fin))
      ]),
      false
    )
    error_message = "maintenance.dates_gel : au plus 12 périodes, debut et fin au format YYYY-MM-DD."
  }
}

# ─── SSO OIDC de l'apiserver ─────────────────────────────────────────────────
variable "oidc" {
  description = <<-EOT
    SSO OIDC de l'apiserver (provider >= 7.6.0) : les utilisateurs se
    connectent avec le fournisseur d'identité de l'organisation (kubelogin).
    `null` (défaut) = pas de SSO ; **retirer le bloc supprime le SSO**. Un
    changement redémarre l'apiserver (envoyé seulement si la configuration
    change réellement).

    - `issuer_url` : `iss` exact des jetons (`https://`, port 443, hôte public).
    - `client_id` : client PUBLIC du fournisseur (PKCE / device flow, sans secret).
    - `username_claim` (défaut provider `email`), `username_prefix` (`oidc:`),
      `groups_claim` (`groups`, `""` = pas de groupes), `groups_prefix`
      (`oidc:`), `extra_scopes` (au plus 10, aucun par défaut), `ca_pem` (CA du
      fournisseur si elle n'est pas publique). Omis = défaut du provider.
  EOT
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

  # Mêmes bornes que le provider v7.6.0 (oidc.go).
  validation {
    condition = var.oidc == null || try(
      can(regex("^https://", var.oidc.issuer_url))
      && length(var.oidc.issuer_url) >= 9 && length(var.oidc.issuer_url) <= 512,
      false
    )
    error_message = "oidc.issuer_url doit commencer par https:// et compter de 9 à 512 caractères."
  }
  validation {
    condition     = var.oidc == null || try(length(var.oidc.client_id) >= 1 && length(var.oidc.client_id) <= 255, false)
    error_message = "oidc.client_id doit compter de 1 à 255 caractères."
  }
  validation {
    condition     = var.oidc == null || length(coalesce(try(var.oidc.extra_scopes, null), [])) <= 10
    error_message = "oidc.extra_scopes : au plus 10 scopes."
  }
}

# ─── Délais d'attente du provider ────────────────────────────────────────────
variable "timeouts" {
  description = <<-EOT
    Délais d'attente du provider (provider >= 7.6.0), durées Go (`30m`,
    `1h30m`), passés tels quels au bloc `timeouts` du cluster. `null` (défaut)
    ou champ omis = défaut du provider :

    - `create` : provisionnement jusqu'à `active` (défaut `15m`).
    - `update` : chaque attente d'une mise à jour — upgrade en cours (`30m`),
      upgrade du control plane (`45m`), upgrade du pool initial (`90m`),
      cluster actif avant un changement de SSO ou de plan (`30m`).
    - `delete` : suppression (défaut `20m`).
  EOT
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default = null

  validation {
    condition = var.timeouts == null || alltrue([
      for d in [try(var.timeouts.create, null), try(var.timeouts.update, null), try(var.timeouts.delete, null)] :
      d == null || can(regex("^([0-9]+(\\.[0-9]+)?(ns|us|µs|ms|s|m|h))+$", d))
    ])
    error_message = "timeouts : chaque durée doit être une durée Go (ex. `30m`, `1h30m`)."
  }
}
