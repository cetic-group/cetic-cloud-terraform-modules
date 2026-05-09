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

variable "vnet_id" {
  type = string
}

variable "k8s_version" {
  type        = string
  default     = "v1.31.4"
  description = "Version Kubernetes du control plane + initial pool."
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
  description = "Initial worker pool créé avec le cluster (immutable post-création)."
  type = object({
    name     = optional(string, "default")
    plan     = optional(string, "small")
    replicas = optional(number, 1)
  })
  default = {}
}

# ─── Pools additionnels ──────────────────────────────────────────────────────
variable "additional_pools" {
  description = <<-EOT
    Map de worker pools supplémentaires à provisionner après le cluster.
    Clé = nom du pool. Valeur :
    - `plan` : `nano` … `xlarge`
    - `replicas` : count (Required)
    - `min_size` / `max_size` : pour autoscaler. Si tous les deux sont set,
      l'autoscaler du cluster gère ce pool.
    - `labels` : map de labels Kubernetes propagés aux nodes via
      MachineDeployment.spec.template.metadata.labels.
  EOT
  type = map(object({
    plan     = string
    replicas = number
    min_size = optional(number)
    max_size = optional(number)
    labels   = optional(map(string), {})
  }))
  default = {}
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
  description = "UUID d'une IP publique pour l'apiserver (kubeconfig public). `null` = privé seulement."
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
