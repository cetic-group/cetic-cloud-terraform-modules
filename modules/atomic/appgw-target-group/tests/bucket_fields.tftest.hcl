# Les valeurs par défaut du mock servent de témoin : un attribut non transmis
# (null dans la configuration) reçoit la valeur du mock lors d'un apply.
# Si le module transmettait la valeur de sa variable, le témoin serait écrasé.
mock_provider "ccp" {
  mock_resource "ccp_appgw_target_group" {
    defaults = {
      id                 = "00000000-0000-0000-0000-00000000d001"
      algorithm          = "mock-algorithm"
      hc_protocol        = "mock-protocol"
      hc_method          = "mock-method"
      hc_path            = "/mock-path"
      sticky_enabled     = true
      sticky_cookie_name = "mock-cookie"
      origin_status      = "drift"
      origin_error       = "bucket redevenu privé"
    }
  }
}

run "bucket_does_not_send_server_fields" {
  command = apply
  variables {
    appgw_id           = "00000000-0000-0000-0000-00000000a001"
    name               = "assets"
    kind               = "bucket"
    bucket_id          = "00000000-0000-0000-0000-00000000b001"
    bucket_prefix      = "site"
    sticky_cookie_name = "SID"
  }
  assert {
    condition     = ccp_appgw_target_group.this.algorithm == "mock-algorithm"
    error_message = "algorithm must not be sent for a bucket target group"
  }
  assert {
    condition     = ccp_appgw_target_group.this.hc_path == "/mock-path"
    error_message = "health check fields must not be sent for a bucket target group"
  }
  assert {
    condition     = ccp_appgw_target_group.this.hc_protocol == "mock-protocol"
    error_message = "hc_protocol must not be sent for a bucket target group"
  }
  assert {
    condition     = ccp_appgw_target_group.this.sticky_enabled == true
    error_message = "sticky_enabled must not be sent for a bucket target group"
  }
  assert {
    condition     = ccp_appgw_target_group.this.sticky_cookie_name == "mock-cookie"
    error_message = "sticky_cookie_name must not be sent for a bucket target group"
  }
  assert {
    condition     = output.kind == "bucket" && output.bucket_id == "00000000-0000-0000-0000-00000000b001" && output.bucket_prefix == "site"
    error_message = "kind, bucket_id and bucket_prefix must be forwarded"
  }
}

run "upstream_sends_server_fields" {
  command = apply
  variables {
    appgw_id           = "00000000-0000-0000-0000-00000000a001"
    name               = "pool"
    sticky_enabled     = true
    sticky_cookie_name = "SID"
  }
  assert {
    condition     = ccp_appgw_target_group.this.algorithm == "roundrobin"
    error_message = "algorithm default must be sent for an upstream target group"
  }
  assert {
    condition     = ccp_appgw_target_group.this.hc_path == "/"
    error_message = "hc_path default must be sent for an upstream target group"
  }
  assert {
    condition     = ccp_appgw_target_group.this.sticky_cookie_name == "SID"
    error_message = "sticky_cookie_name must be sent for an upstream target group"
  }
}

run "origin_outputs_are_exposed" {
  command = apply
  variables {
    appgw_id  = "00000000-0000-0000-0000-00000000a001"
    name      = "assets"
    kind      = "bucket"
    bucket_id = "00000000-0000-0000-0000-00000000b001"
  }
  assert {
    condition     = output.origin_status == "drift"
    error_message = "origin_status must be exposed"
  }
  assert {
    condition     = output.origin_error == "bucket redevenu privé"
    error_message = "origin_error must be exposed"
  }
}
