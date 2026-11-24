terraform {
  required_version = ">= 1.9"
  required_providers {
    ccp = {
      source  = "cetic-group/ccp"
      version = ">= 7.6.0"
    }
  }
}
