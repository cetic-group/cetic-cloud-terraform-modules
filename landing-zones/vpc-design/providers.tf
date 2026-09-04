terraform {
  required_version = ">= 1.7"
  required_providers {
    ccp = {
      source  = "cetic-group/ccp"
      version = ">= 6.3.0"
    }
  }
}

provider "ccp" {}

