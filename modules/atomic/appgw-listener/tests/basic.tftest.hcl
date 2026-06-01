mock_provider "ccp" {
  mock_resource "ccp_appgw_listener" {
    defaults = {
      id                   = "00000000-0000-0000-0000-00000000f001"
      acme_status          = "issued"
      acme_last_renewal_at = "2026-05-16T08:00:00Z"
      cert_path            = "/var/lib/ccp-appgw/certs/api.example.com.pem"
      created_at           = "2026-05-16T07:00:00Z"
    }
  }
}

run "creates_with_auto_subdomain" {
  command = plan
  variables {
    appgw_id = "00000000-0000-0000-0000-00000000a001"
    hostname = "acme-rnn.app.cloud.cetic-group.com"
  }
  assert {
    condition     = ccp_appgw_listener.this.hostname == "acme-rnn.app.cloud.cetic-group.com"
    error_message = "hostname not propagated"
  }
  assert {
    condition     = ccp_appgw_listener.this.custom_domain == false
    error_message = "custom_domain default should be false"
  }
}

run "creates_with_custom_domain" {
  command = plan
  variables {
    appgw_id      = "00000000-0000-0000-0000-00000000a001"
    hostname      = "api.example.com"
    custom_domain = true
  }
  assert {
    condition     = ccp_appgw_listener.this.custom_domain == true
    error_message = "custom_domain should be true"
  }
}

run "rejects_uppercase_hostname" {
  command = plan
  variables {
    appgw_id = "00000000-0000-0000-0000-00000000a001"
    hostname = "API.example.com"
  }
  expect_failures = [
    var.hostname,
  ]
}

run "rejects_hostname_with_underscore" {
  command = plan
  variables {
    appgw_id = "00000000-0000-0000-0000-00000000a001"
    hostname = "bad_host.example.com"
  }
  expect_failures = [
    var.hostname,
  ]
}
