mock_provider "ccp" {
  mock_resource "ccp_db_pg_instance" {
    defaults = {
      id                   = "00000000-0000-0000-0000-000000000001"
      tier                 = "dev"
      endpoint_vnet_ip     = "10.0.1.10"
      endpoint_port        = 5432
      admin_username       = "admin"
      admin_database       = "app"
      status               = "running"
      extensions_available = true
      extensions_status    = "applied"
    }
  }
}

variables {
  name    = "db"
  region  = "RNN"
  vpc_id  = "00000000-0000-0000-0000-0000000000aa"
  vnet_id = "00000000-0000-0000-0000-0000000000bb"
}

run "extensions_passthrough" {
  command = apply
  variables {
    allowed_extensions = ["pg_cron", "pg_stat_statements"]
    preload_libraries  = ["pg_cron"]
    cron_database      = "app"
  }
  assert {
    condition     = ccp_db_pg_instance.this.allowed_extensions == toset(["pg_cron", "pg_stat_statements"])
    error_message = "allowed_extensions non propagé"
  }
  assert {
    condition     = ccp_db_pg_instance.this.preload_libraries == toset(["pg_cron"])
    error_message = "preload_libraries non propagé"
  }
  assert {
    condition     = ccp_db_pg_instance.this.cron_database == "app"
    error_message = "cron_database non propagé"
  }
  assert {
    condition     = output.extensions_available == true && output.extensions_status == "applied"
    error_message = "outputs d'extensions non exposés"
  }
}

run "empty_sets_propagated" {
  command = plan
  variables {
    allowed_extensions = []
    preload_libraries  = []
  }
  assert {
    condition     = length(ccp_db_pg_instance.this.allowed_extensions) == 0 && length(ccp_db_pg_instance.this.preload_libraries) == 0
    error_message = "[] doit être transmis tel quel (aucune extension)"
  }
}
