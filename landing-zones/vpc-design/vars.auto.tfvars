vpc_map = {
  vpc-prod-10-1 = {
    region = "RNN"
    vnets = {
      vnet-10-1-1 = { cidr = "10.1.1.0/24", snat = false, tags = ["web"], isolated = true
        firewall_rules = [
          { direction = "in", protocol = "tcp", source_cidr = "10.1.2.0/24", port = "80", description = "HTTP depuis web" },
          { direction = "in", protocol = "tcp", source_cidr = "10.1.2.0/24", port = "443", description = "HTTPS depuis web" },
          { direction = "in", protocol = "tcp", source_cidr = "10.1.2.0/24", port = "5432", description = "PostgreSQL depuis web" },
          { direction = "in", protocol = "tcp", source_cidr = "10.1.2.0/24", port = "5432", description = "PG depuis peer prod-10-1-web" },
        ]
      }
      vnet-10-1-2 = {
        cidr     = "10.1.2.0/24"
        snat     = false
        tags     = ["data"]
        isolated = true
        # isolated=true active le firewall L3 du VNet (DROP par défaut sur
        # le trafic inter-VNet). Les firewall_rules ci-dessous ne sont
        # effectives qu'avec isolated=true. Géré via le provider depuis
        # cetic-cloud-terraform-modules v0.3.2 / provider v0.9.x.
        firewall_rules = [
          { direction = "in", protocol = "tcp", source_cidr = "10.1.1.0/24", port = "80", description = "HTTP depuis web" },
          { direction = "in", protocol = "tcp", source_cidr = "10.1.1.0/24", port = "443", description = "HTTPS depuis web" },
          { direction = "in", protocol = "tcp", source_cidr = "10.1.1.0/24", port = "5432", description = "PostgreSQL depuis web" },
          { direction = "in", protocol = "tcp", source_cidr = "10.1.1.0/24", port = "5432", description = "PG depuis peer prod-10-1-web" },
        ]
      }
    }
  }
  vpc-staging-10-2 = {
    region = "RNN"
    vnets = {
      vnet-10-2-1 = { cidr = "10.2.1.0/24", snat = false, tags = ["web"] }
      vnet-10-2-2 = { cidr = "10.2.2.0/24", snat = false, tags = ["data"] }
    }
  }
  vpc-dev-10-3 = {
    region = "RNN"
    vnets = {
      vnet-10-3-1 = { cidr = "10.3.1.0/24", snat = false, tags = ["web"] }
      vnet-10-3-2 = { cidr = "10.3.2.0/24", snat = false, tags = ["data"] }
    }
  }
}
