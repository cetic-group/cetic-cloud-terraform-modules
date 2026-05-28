mock_provider "cetic-cloud-platform" {
  mock_resource "ccp_budget" {
    defaults = {
      id                       = "00000000-0000-0000-0000-000000000001"
      tenant_id                = "00000000-0000-0000-0000-000000000099"
      currency                 = "eur"
      last_alert_threshold_pct = null
      active                   = true
    }
  }
  mock_resource "ccp_commit" {
    defaults = {
      id           = "00000000-0000-0000-0000-000000000002"
      tenant_id    = "00000000-0000-0000-0000-000000000099"
      discount_pct = 20
      start_at     = "2026-05-16T00:00:00Z"
      end_at       = "2027-05-16T00:00:00Z"
      canceled_at  = ""
    }
  }
}

run "minimal_budget_no_commit" {
  command = plan
  variables {
    monthly_budget_eur = 30
  }
  assert {
    condition     = ccp_budget.this.monthly_budget_cents == 3000
    error_message = "Should convert euros to cents (30 * 100)."
  }
  assert {
    condition     = length(ccp_commit.this) == 0
    error_message = "No commit should be created when commit_type is null."
  }
}

run "budget_with_yearly_commit" {
  command = plan
  variables {
    monthly_budget_eur = 100
    commit_type        = "yearly"
    hard_stop_at_100   = true
  }
  assert {
    condition     = ccp_budget.this.monthly_budget_cents == 10000
    error_message = "Should convert 100 EUR to 10000 cents."
  }
  assert {
    condition     = ccp_budget.this.hard_stop_at_100 == true
    error_message = "hard_stop_at_100 should propagate."
  }
  assert {
    condition     = length(ccp_commit.this) == 1
    error_message = "Should create one ccp_commit resource for yearly."
  }
  assert {
    condition     = ccp_commit.this[0].commit_type == "yearly"
    error_message = "commit_type should be yearly."
  }
}

run "rejects_invalid_commit_type" {
  command = plan
  variables {
    monthly_budget_eur = 50
    commit_type        = "weekly"
  }
  expect_failures = [var.commit_type]
}

run "rejects_negative_budget" {
  command = plan
  variables {
    monthly_budget_eur = -10
  }
  expect_failures = [var.monthly_budget_eur]
}

run "custom_thresholds_and_emails" {
  command = plan
  variables {
    monthly_budget_eur   = 200
    alert_thresholds_pct = [25, 50, 75, 90, 100]
    notify_emails        = ["a@example.com", "b@example.com"]
  }
  assert {
    condition     = length(ccp_budget.this.alert_thresholds_pct) == 5
    error_message = "Should propagate 5 thresholds."
  }
  assert {
    condition     = length(ccp_budget.this.notify_emails) == 2
    error_message = "Should propagate 2 emails."
  }
}
