terraform {
  required_version = ">= 1.7"
  required_providers {
    ccp = {
      source  = "cetic-group/cetic-cloud-platform"
      version = ">= 0.16.0"
    }
  }
}
