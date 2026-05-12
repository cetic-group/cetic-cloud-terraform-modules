locals {
  # Carte env → {service_account_name, role_name, registry_arn_pattern}
  env_specs = {
    for e in var.envs : e => {
      sa_name          = "ci-${e}"
      role_name        = "RegistryDeployer-${e}"
      registry_arn     = "arn:ccp:registry:${var.region}:${var.tenant_id}:registry/${e}-*"
      registry_arn_obj = "arn:ccp:registry:${var.region}:${var.tenant_id}:registry/${e}-*/repository/*"
    }
  }
}

# ─── Per-env service accounts (CI bots) ───────────────────────────────────────
module "ci_sa" {
  source = "../../modules/atomic/service-account"

  for_each = local.env_specs

  name        = each.value.sa_name
  description = "CI deploy bot for env=${each.key}. Auto-attached to ${each.value.role_name}."
  expires_at  = var.sa_expires_at
}

# ─── Per-env RegistryDeployer roles (push restreint au préfixe de l'env) ──────
module "registry_deployer" {
  source = "../../modules/managed/iam-role"

  for_each = local.env_specs

  name        = each.value.role_name
  description = "Push/Pull autorisé uniquement sur les registries dont le slug commence par '${each.key}-'."

  statements = [
    {
      sid       = "AllowRegistryPushPull"
      effect    = "Allow"
      actions   = ["registry:Push", "registry:Pull", "registry:Get*", "registry:List*"]
      resources = [each.value.registry_arn, each.value.registry_arn_obj]
    },
    {
      sid       = "DenyDestructive"
      effect    = "Deny"
      actions   = ["registry:Delete*", "registry:RunGarbageCollection"]
      resources = ["*"]
    },
  ]
}

# ─── Per-env assignment SA ↔ RegistryDeployer ─────────────────────────────────
module "ci_can_deploy" {
  source = "../../modules/atomic/iam-role-assignment"

  for_each = local.env_specs

  role_id        = module.registry_deployer[each.key].role_id
  principal_type = "service_account"
  principal_id   = module.ci_sa[each.key].id
}

# ─── BillingViewer (transverse, lecture seule) ────────────────────────────────
module "billing_viewer" {
  source = "../../modules/managed/iam-role"

  name        = "BillingViewer"
  description = "Lecture seule sur la facturation du tenant (tous environnements)."

  statements = [
    {
      sid       = "AllowBillingRead"
      effect    = "Allow"
      actions   = ["billing:Get*", "billing:List*"]
      resources = ["arn:ccp:billing:::${var.tenant_id}:*"]
    },
  ]
}

# ─── BillingViewer assignment (optionnel — si un member ID est fourni) ────────
module "billing_viewer_member" {
  source = "../../modules/atomic/iam-role-assignment"

  count = var.billing_viewer_member_id == null ? 0 : 1

  role_id        = module.billing_viewer.role_id
  principal_type = "org_member"
  principal_id   = var.billing_viewer_member_id
}
