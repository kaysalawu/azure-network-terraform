####################################################
# Lab
####################################################

locals {
  prefix                 = "Lab04"
  lab_name               = "AppGwWebsocket"
  enable_diagnostics     = false
  enable_onprem_wan_link = false
  hub1_tags              = { "lab" = local.prefix, "nodeType" = "hub" }
  hub1_appgw_pip         = azurerm_public_ip.hub1_appgw_pip.ip_address
  hub1_host_server       = "server-${local.hub1_appgw_pip}.nip.io"
}

####################################################
# providers
####################################################

provider "azurerm" {
  resource_provider_registrations = "none"
  subscription_id                 = var.subscription_id
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
      nsg_subnet_map = {
        "MainSubnet"      = module.common.nsg_main["region1"].id
        "TrustSubnet"     = module.common.nsg_main["region1"].id
        "DnsServerSubnet" = module.common.nsg_main["region1"].id
      }
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

####################################################
# output files
####################################################

locals {
  main_files = {
  }
}

resource "local_file" "main_files" {
  for_each = local.main_files
  filename = each.key
  content  = each.value
}
