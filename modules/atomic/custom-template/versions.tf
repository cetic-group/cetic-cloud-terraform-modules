terraform {
  required_version = ">= 1.7"
  required_providers {
    cetic-cloud-platform = {
      source  = "cetic-group/cetic-cloud-platform"
      version = ">= 2.0.0"
    }
  }
}
