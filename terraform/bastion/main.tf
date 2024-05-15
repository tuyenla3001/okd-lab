terraform {
  required_version = ">=1.2.2"
  required_providers {
    vsphere = {
      source  = "hashicorp/vsphere"
      version = "~> 2.7.0"
    }
  }
}
