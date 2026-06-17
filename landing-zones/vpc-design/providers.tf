terraform {
  required_version = ">= 1.7"
  required_providers {
    ccp = {
      source  = "cetic-group/ccp"
      version = ">= 5.0.0"
    }
  }
}

provider "ccp" {}

