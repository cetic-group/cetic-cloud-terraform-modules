resource "ccp_k8s_cluster" "this" {
  provider        = cetic-cloud-platform
  name            = var.name
  display_name    = coalesce(var.display_name, var.name)
  region          = var.region
  tier            = var.tier
  vpc_id          = var.vpc_id
  vnet_id         = var.vnet_id
  k8s_version     = var.k8s_version
  os_template_key = var.os_template_key
  pod_cidr        = var.pod_cidr
  service_cidr    = var.service_cidr

  initial_pool {
    name     = var.initial_pool.name
    plan     = var.initial_pool.plan
    replicas = var.initial_pool.replicas
    # Autoscaler sur l'initial pool (provider v3.1.0+). Les deux set → activé ;
    # retirés → désactivé (le provider envoie 0/0). Passés tels quels (null = omis).
    min_size = var.initial_pool.min_size
    max_size = var.initial_pool.max_size
  }

  autoscaler_scale_down_delay_after_add = var.autoscaler_scale_down_delay_after_add
  autoscaler_scale_down_unneeded_time   = var.autoscaler_scale_down_unneeded_time

  ingress_controller_enabled = var.ingress_controller_enabled
  ingress_controller_scope   = var.ingress_controller_scope
  ingress_controller_class   = var.ingress_controller_class
  ingress_public_ip_id       = var.ingress_public_ip_id
  ingress_internal_ip        = var.ingress_internal_ip

  # IP publique apiserver — mutable depuis provider v3.0.0 (attach/détach/rotate
  # sans recréer le cluster). Plus de `public_ip_id` séparé (supprimé en v3).
  apiserver_public_ip_id = var.apiserver_public_ip_id
  apiserver_internal_ip  = var.apiserver_internal_ip

  tags = var.tags
}

# ─── Pools additionnels ──────────────────────────────────────────────────────
resource "ccp_k8s_node_pool" "additional" {
  provider = cetic-cloud-platform
  for_each = var.additional_pools

  cluster_id = ccp_k8s_cluster.this.id
  name       = each.key
  plan       = each.value.plan
  replicas   = each.value.replicas
  min_size   = each.value.min_size
  max_size   = each.value.max_size
  labels     = each.value.labels
  taints     = each.value.taints
}
