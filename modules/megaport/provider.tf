
terraform {
  required_providers {
    megaport = {
      source = "megaport/megaport"
      #version = "0.1.9"
    }
  }
}

provider "megaport" {
  access_key            = var.access_key
  secret_key            = var.secret_key
  accept_purchase_terms = true
  delete_ports          = true
  environment           = "production"
}
