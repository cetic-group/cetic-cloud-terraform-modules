resource "ccp_support_subscription" "this" {
  provider = ccp
  plan_key = var.plan_key
}

# Datasource enrichit les outputs (price, SLA, channels) pour les composers.
data "ccp_support_plan" "this" {
  provider = ccp
  key      = var.plan_key
}
