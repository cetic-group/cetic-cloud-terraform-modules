locals {
  # Normalise le rattachement VPC : `vpc_ids` prioritaire, sinon `vpc_id` seul.
  vpc_ids = var.vpc_ids != null ? var.vpc_ids : (var.vpc_id != null ? [var.vpc_id] : [])
  # Le provider exige un VPC primaire (`vpc_id`, Required) toujours inclus dans
  # l'ensemble. On prend `var.vpc_id` s'il est fourni, sinon le 1er de `vpc_ids`.
  primary_vpc_id = var.vpc_id != null ? var.vpc_id : (length(local.vpc_ids) > 0 ? local.vpc_ids[0] : null)
  # `vpc_ids` n'est transmis que pour un bastion multi-VPC ; pour un VPC unique on
  # laisse le provider dériver l'ensemble depuis `vpc_id` (évite un faux diff).
  vpc_ids_arg = length(local.vpc_ids) > 1 ? local.vpc_ids : null
}

# ── Bastion SSH — point d'entrée audité vers les instances privées du VPC ──────
resource "ccp_bastion" "this" {
  provider = ccp

  name         = var.name
  region       = var.region
  plan         = var.plan
  vpc_id       = local.primary_vpc_id
  vpc_ids      = local.vpc_ids_arg
  public_ip_id = var.public_ip_id
  tags         = var.tags

  lifecycle {
    precondition {
      condition     = length(local.vpc_ids) >= 1
      error_message = "Au moins un VPC doit être rattaché : fournissez `vpc_ids` (liste) ou `vpc_id` (unique)."
    }
    precondition {
      condition     = length(local.vpc_ids) <= 5
      error_message = "Un bastion peut fronter au plus 5 VPC."
    }
  }
}
