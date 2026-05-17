resource "ccp_support_subscription" "this" {
  plan_key = var.plan_key
}

# Datasource enrichit les outputs (price, SLA, channels) pour les composers.
data "ccp_support_plan" "this" {
  key = var.plan_key
}
