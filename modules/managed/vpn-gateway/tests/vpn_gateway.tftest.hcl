mock_provider "ccp" {
  mock_resource "ccp_vpn_gateway" {
    defaults = {
      id                = "00000000-0000-0000-0000-000000000001"
      status            = "active"
      endpoint_host     = "vpn-rnn-aabbccdd.cloud.cetic-group.com"
      endpoint_port     = 51820
      public_key        = "GatewayPublicKeyBase64Example="
      public_ip_address = "203.0.113.10"
    }
  }
  mock_resource "ccp_vpn_peer" {
    defaults = {
      id     = "00000000-0000-0000-0000-0000000000aa"
      ip     = "10.99.0.2"
      config = "[Interface]\nPrivateKey = ...\n"
    }
  }
}

run "creates_gateway_with_single_vpc" {
  command = plan
  variables {
    name   = "ops"
    region = "RNN"
    vpc_id = "00000000-0000-0000-0000-0000000000ff"
  }
  assert {
    condition     = ccp_vpn_gateway.this.name == "ops"
    error_message = "name not propagated"
  }
  assert {
    condition     = ccp_vpn_gateway.this.plan == "small"
    error_message = "plan should default to small"
  }
  assert {
    condition     = ccp_vpn_gateway.this.vpc_ids == tolist(["00000000-0000-0000-0000-0000000000ff"])
    error_message = "vpc_id should be normalised into vpc_ids"
  }
}

run "creates_gateway_with_multi_vpc_and_peers" {
  command = plan
  variables {
    name           = "multi"
    region         = "PAR"
    plan           = "medium"
    vpc_ids        = ["00000000-0000-0000-0000-0000000000a1", "00000000-0000-0000-0000-0000000000a2"]
    peer_pool_cidr = "10.99.0.0/24"
    dns            = ["10.10.0.2"]
    peers = {
      alice = {
        public_key = "AlicePublicKeyBase64Example="
      }
      laptop-ci = {
        managed           = true
        store_private_key = true
      }
    }
  }
  assert {
    condition     = length(ccp_vpn_gateway.this.vpc_ids) == 2
    error_message = "both VPCs should be attached"
  }
  assert {
    condition     = length(ccp_vpn_peer.this) == 2
    error_message = "two peers should be created"
  }
  assert {
    condition     = ccp_vpn_peer.this["alice"].public_key == "AlicePublicKeyBase64Example="
    error_message = "client-provided public key should propagate"
  }
}

run "rejects_invalid_plan" {
  command = plan
  variables {
    name   = "bad"
    region = "RNN"
    vpc_id = "00000000-0000-0000-0000-0000000000ff"
    plan   = "xlarge"
  }
  expect_failures = [var.plan]
}

run "rejects_peer_with_both_key_and_managed" {
  command = plan
  variables {
    name   = "bad"
    region = "RNN"
    vpc_id = "00000000-0000-0000-0000-0000000000ff"
    peers = {
      conflict = {
        public_key = "SomeKey="
        managed    = true
      }
    }
  }
  expect_failures = [var.peers]
}
