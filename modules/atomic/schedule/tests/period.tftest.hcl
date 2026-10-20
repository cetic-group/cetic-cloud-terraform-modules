mock_provider "ccp" {}

variables {
  name          = "lundis"
  resource_type = "vm"
  resource_id   = "11111111-1111-1111-1111-111111111111"
  windows       = [{ start_day = 0, start_hour = 8, end_day = 0, end_hour = 20 }]
}

run "sans_periode" {
  command = plan
  assert {
    condition     = ccp_schedule.this.starts_on == null && ccp_schedule.this.ends_on == null
    error_message = "Sans période, aucune borne ne doit être envoyée."
  }
}

run "periode_transmise" {
  command = plan
  variables {
    starts_on = "2026-10-20"
    ends_on   = "2027-02-19"
  }
  assert {
    condition     = ccp_schedule.this.starts_on == "2026-10-20" && ccp_schedule.this.ends_on == "2027-02-19"
    error_message = "Les bornes doivent être transmises telles quelles."
  }
}

run "date_invalide" {
  command = plan
  variables {
    ends_on = "19/02/2027"
  }
  expect_failures = [var.ends_on]
}
