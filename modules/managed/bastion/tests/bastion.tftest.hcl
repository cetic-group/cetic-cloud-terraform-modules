mock_provider "ccp" {
  mock_resource "ccp_bastion" {
    defaults = {
      id                = "00000000-0000-0000-0000-000000000001"
      status            = "active"
      endpoint_host     = "bastion-rnn-aabbccdd.cloud.cetic-group.com"
      endpoint_port     = 2222
      public_ip_address = "203.0.113.20"
    }
  }
}

run "creates_bastion_with_single_vpc" {
  command = plan
  variables {
    name   = "ops"
    region = "RNN"
    vpc_id = "00000000-0000-0000-0000-0000000000ff"
  }
  assert {
    condition     = ccp_bastion.this.name == "ops"
    error_message = "name not propagated"
  }
  assert {
    condition     = ccp_bastion.this.vpc_id == "00000000-0000-0000-0000-0000000000ff"
    error_message = "vpc_id should be propagated as the primary VPC"
  }
  assert {
    condition     = ccp_bastion.this.region == "RNN"
    error_message = "region not propagated"
  }
  assert {
    condition     = ccp_bastion.this.plan == "small"
    error_message = "plan should default to small"
  }
  # NB : en VPC unique le module laisse `vpc_ids` à null en config, mais
  # l'attribut provider est Optional+Computed → valeur (unknown) au plan, donc
  # non assertable ici. Le rattachement primaire est couvert par l'assert vpc_id
  # ci-dessus ; le passage de la liste est testé dans le run multi-VPC.
}

run "creates_bastion_multi_vpc_with_plan_and_tags" {
  command = plan
  variables {
    name    = "multi"
    region  = "PAR"
    plan    = "medium"
    vpc_ids = ["00000000-0000-0000-0000-0000000000a1", "00000000-0000-0000-0000-0000000000a2"]
    tags    = ["env:prod", "team:ops"]
  }
  assert {
    condition     = ccp_bastion.this.vpc_id == "00000000-0000-0000-0000-0000000000a1"
    error_message = "primary vpc_id should be the first of vpc_ids"
  }
  assert {
    condition     = ccp_bastion.this.vpc_ids == tolist(["00000000-0000-0000-0000-0000000000a1", "00000000-0000-0000-0000-0000000000a2"])
    error_message = "multi-VPC bastion should pass the full vpc_ids list"
  }
  assert {
    condition     = ccp_bastion.this.plan == "medium"
    error_message = "plan should propagate"
  }
  assert {
    condition     = ccp_bastion.this.tags == tolist(["env:prod", "team:ops"])
    error_message = "tags should propagate"
  }
}

run "creates_bastion_with_public_ip" {
  command = plan
  variables {
    name         = "with-ip"
    region       = "RNN"
    vpc_id       = "00000000-0000-0000-0000-0000000000ff"
    public_ip_id = "00000000-0000-0000-0000-0000000000ee"
  }
  assert {
    condition     = ccp_bastion.this.public_ip_id == "00000000-0000-0000-0000-0000000000ee"
    error_message = "public_ip_id should propagate"
  }
}

run "rejects_invalid_region" {
  command = plan
  variables {
    name   = "bad"
    region = "ZZZ"
    vpc_id = "00000000-0000-0000-0000-0000000000ff"
  }
  expect_failures = [var.region]
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

run "rejects_invalid_name" {
  command = plan
  variables {
    name   = "bad/name!"
    region = "RNN"
    vpc_id = "00000000-0000-0000-0000-0000000000ff"
  }
  expect_failures = [var.name]
}

run "rejects_too_many_tags" {
  command = plan
  variables {
    name   = "bad"
    region = "RNN"
    vpc_id = "00000000-0000-0000-0000-0000000000ff"
    tags   = [for i in range(61) : "tag-${i}"]
  }
  expect_failures = [var.tags]
}

run "rejects_no_vpc" {
  command = plan
  variables {
    name   = "bad"
    region = "RNN"
  }
  expect_failures = [ccp_bastion.this]
}

run "rejects_too_many_vpcs" {
  command = plan
  variables {
    name   = "bad"
    region = "RNN"
    vpc_ids = [
      "00000000-0000-0000-0000-0000000000a1",
      "00000000-0000-0000-0000-0000000000a2",
      "00000000-0000-0000-0000-0000000000a3",
      "00000000-0000-0000-0000-0000000000a4",
      "00000000-0000-0000-0000-0000000000a5",
      "00000000-0000-0000-0000-0000000000a6",
    ]
  }
  expect_failures = [ccp_bastion.this]
}
