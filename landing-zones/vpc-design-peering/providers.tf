terraform {
  required_version = ">= 1.7"
  required_providers {
    cetic-cloud-platform = {
      source  = "cetic-group/cetic-cloud-platform"
      version = ">= 1.1.2"
    }
  }
}

provider "cetic-cloud-platform" {}

