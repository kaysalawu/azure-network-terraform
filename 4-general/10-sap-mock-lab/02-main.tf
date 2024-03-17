####################################################
# Lab
####################################################

locals {
  prefix                   = "G10"
  lab_name                 = "SapNetworking"
  enable_diagnostics       = false
  enable_service_endpoints = false
  ecs_tags                 = { "lab" = local.prefix, "nodeType" = "hub" }
  onprem_tags              = { "lab" = local.prefix, "nodeType" = "branch" }
}

resource "random_id" "random" {
  byte_length = 2
}

data "azurerm_client_config" "current" {}

####################################################
# providers
####################################################

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

terraform {
  required_providers {
    megaport = {
      source  = "megaport/megaport"
      version = "0.4.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.78.0"
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
  ecs_features = {
    config_vnet = {
      address_space                = local.ecs_address_space
      subnets                      = local.ecs_subnets
      enable_private_dns_resolver  = false
      enable_ars                   = false
      ruleset_dns_forwarding_rules = {}
    }
    config_s2s_vpngw = {
      enable = true
      sku    = "VpnGw1AZ"
      ip_configuration = [
        { name = "ipconf0", public_ip_address_name = azurerm_public_ip.ecs_s2s_vpngw_pip0.name, apipa_addresses = ["169.254.21.1"] },
        { name = "ipconf1", public_ip_address_name = azurerm_public_ip.ecs_s2s_vpngw_pip1.name, apipa_addresses = ["169.254.21.5"] }
      ]
      bgp_settings = {
        asn = local.ecs_vpngw_asn
      }
    }
    config_p2s_vpngw = { enable = false }
    config_ergw      = { enable = false }
    config_firewall  = { enable = false }
    config_nva       = { enable = false }
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
  regions          = local.regions
  private_prefixes = local.private_prefixes
  tags             = {}
}

# vm startup scripts
#----------------------------

locals {
  ecs_vpngw_asn = "65515"
  vm_script_targets_region1 = [
    { name = "onprem", dns = lower(local.onprem_vm_fqdn), ip = local.onprem_vm_addr, probe = true },
  ]
  vm_script_targets_misc = [
    { name = "internet", dns = "icanhazip.com", ip = "icanhazip.com" },
  ]
  vm_script_targets = concat(
    local.vm_script_targets_region1,
    local.vm_script_targets_misc,
  )
  vm_startup = templatefile("../../scripts/server.sh", {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
  })
  onprem_local_records = [
    { name = lower(local.onprem_vm_fqdn), record = local.onprem_vm_addr },
  ]
  onprem_redirected_hosts = []
  branch_dns_init_dir     = "/var/lib/labs"
}


####################################################
# addresses
####################################################

# onprem

resource "azurerm_public_ip" "onprem_nva_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.onprem_prefix}nva-pip"
  location            = local.onprem_location
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = local.onprem_tags
}

# ecs

resource "azurerm_public_ip" "ecs_s2s_vpngw_pip0" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.ecs_prefix}s2s-vpngw-pip0"
  location            = local.ecs_location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = [1, 2, 3]
  tags                = local.ecs_tags
}

resource "azurerm_public_ip" "ecs_s2s_vpngw_pip1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.ecs_prefix}s2s-vpngw-pip1"
  location            = local.ecs_location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = [1, 2, 3]
  tags                = local.ecs_tags
}

####################################################
# output files
####################################################

locals {
  main_files = {
    "output/server.sh" = local.vm_startup
  }
}

resource "local_file" "main_files" {
  for_each = local.main_files
  filename = each.key
  content  = each.value
}
