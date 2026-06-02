mock_provider "ccp" {
  mock_resource "ccp_appgw_listener" {
    defaults = {
      id                   = "00000000-0000-0000-0000-00000000f001"
      acme_status          = "issued"
      acme_issued_at       = "2026-05-16T08:00:00Z"
      acme_renew_after     = "2026-07-15T08:00:00Z"
      acme_last_renewal_at = "2026-05-16T08:00:00Z"
      cert_path            = "/var/lib/ccp-appgw/certs/api.example.com.pem"
      created_at           = "2026-05-16T07:00:00Z"
    }
  }
}

run "creates_without_acme" {
  command = plan
  variables {
    appgw_id = "00000000-0000-0000-0000-00000000a001"
    hostname = "plain.app.cloud.cetic-group.com"
  }
  assert {
    condition     = ccp_appgw_listener.this.hostname == "plain.app.cloud.cetic-group.com"
    error_message = "hostname not propagated"
  }
  assert {
    condition     = ccp_appgw_listener.this.acme_challenge == null
    error_message = "acme_challenge should default to null"
  }
}

run "creates_with_http01" {
  command = plan
  variables {
    appgw_id       = "00000000-0000-0000-0000-00000000a001"
    hostname       = "api.example.com"
    acme_challenge = "http01"
  }
  assert {
    condition     = ccp_appgw_listener.this.acme_challenge == "http01"
    error_message = "acme_challenge should be http01"
  }
}

run "creates_with_dns01" {
  command = plan
  variables {
    appgw_id          = "00000000-0000-0000-0000-00000000a001"
    hostname          = "admin.example.com"
    acme_challenge    = "dns01"
    acme_dns_provider = "cloudflare"
    acme_dns_credentials = {
      api_token = "secret-token"
    }
  }
  assert {
    condition     = ccp_appgw_listener.this.acme_challenge == "dns01"
    error_message = "acme_challenge should be dns01"
  }
  assert {
    condition     = ccp_appgw_listener.this.acme_dns_provider == "cloudflare"
    error_message = "acme_dns_provider should be propagated"
  }
}

run "rejects_invalid_acme_challenge" {
  command = plan
  variables {
    appgw_id       = "00000000-0000-0000-0000-00000000a001"
    hostname       = "api.example.com"
    acme_challenge = "tls-alpn"
  }
  expect_failures = [
    var.acme_challenge,
  ]
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
