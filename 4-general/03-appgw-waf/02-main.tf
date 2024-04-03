####################################################
# Lab
####################################################

locals {
  prefix                 = "Lab03"
  lab_name               = "AppGwWaf"
  enable_diagnostics     = false
  enable_onprem_wan_link = false
  hub1_tags              = { "lab" = local.prefix, "nodeType" = "hub" }
  hub1_appgw_pip         = azurerm_public_ip.hub1_appgw_pip.ip_address
  hub1_host_good_juice   = "good-juice-${local.hub1_appgw_pip}.nip.io"
  hub1_host_bad_juice    = "bad-juice-${local.hub1_appgw_pip}.nip.io"
}

####################################################
# providers
####################################################

provider "azurerm" {
  skip_provider_registration = true
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.78.0"
    }
    azapi = {
      source = "azure/azapi"
    }
  }
}

####################################################
# network features
####################################################

locals {
  regions = {
    "region1" = { name = local.region1, dns_zone = local.region1_dns_zone }
  }
  firewall_sku = "Basic"

  hub1_features = {
    config_vnet = {
      address_space = local.hub1_address_space
      subnets       = local.hub1_subnets
      nat_gateway_subnet_names = [
        "MainSubnet",
        "TrustSubnet",
      ]
    }

    config_s2s_vpngw = {
      enable = false
    }

    config_p2s_vpngw = {
      enable                   = false
      ip_configuration         = []
      vpn_client_configuration = {}
    }

    config_ergw = {
      enable = false
    }

    config_firewall = {
      enable = false
    }

    config_nva = {
      enable = false
      type   = null
    }
  }
}

####################################################
# common resources
####################################################

# resource group

resource "azurerm_resource_group" "rg" {
  name     = "${local.prefix}_${local.lab_name}_RG"
  location = local.default_region
  tags = {
    prefix   = local.prefix
    lab_name = local.lab_name
  }
}

module "common" {
  source           = "../../modules/common"
  resource_group   = azurerm_resource_group.rg.name
  env              = "common"
  prefix           = local.prefix
  firewall_sku     = local.firewall_sku
  regions          = local.regions
  private_prefixes = local.private_prefixes
  tags             = {}
}

# vm startup scripts
#----------------------------

locals {
  vm_startup_juice = templatefile("./scripts/juice-cloud-init.tpl", {})
  vm_startup_test = templatefile("./scripts/hacker.sh", {
    TARGETS         = []
    HOST_BAD_JUICE  = ""
    HOST_GOOD_JUICE = ""
  })
}

####################################################
# addresses
####################################################

resource "azurerm_public_ip" "hub1_appgw_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}appgw-pip"
  location            = local.hub1_location
  sku                 = "Standard"
  allocation_method   = "Static"
}

