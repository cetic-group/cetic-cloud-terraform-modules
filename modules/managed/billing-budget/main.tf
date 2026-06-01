# Module composé `managed/billing-budget` — un budget mensuel + alertes,
# avec option d'engagement (commit -10% mensuel ou -20% annuel) en une
# seule entrée HCL.
#
# Pas de gestion de codes promo ici : ils s'appliquent une fois par tenant
# au signup, hors workflow Terraform habituel.

resource "ccp_budget" "this" {
  provider             = ccp
  monthly_budget_cents = floor(var.monthly_budget_eur * 100)
  alert_thresholds_pct = var.alert_thresholds_pct
  notify_emails        = var.notify_emails
  hard_stop_at_100     = var.hard_stop_at_100
}

resource "ccp_commit" "this" {
  provider = ccp
  count    = var.commit_type == null ? 0 : 1

  commit_type = var.commit_type
  auto_renew  = var.commit_auto_renew
}
