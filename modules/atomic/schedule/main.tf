resource "ccp_schedule" "this" {
  provider = ccp

  name          = var.name
  resource_type = var.resource_type
  resource_id   = var.resource_id
  timezone      = var.timezone
  enabled       = var.enabled

  windows = [
    for w in var.windows : {
      start_day  = w.start_day
      start_hour = w.start_hour
      end_day    = w.end_day
      end_hour   = w.end_hour
    }
  ]
}
