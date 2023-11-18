

locals {
  core1_bak_srv_nic = module.core1.interface["bak-srv"].name
  core2_bak_srv_nic = module.core2.interface["bak-srv"].name
  yellow_vm_nic     = module.yellow.interface["vm"].name
}

####################################################
# core1
####################################################

# base

module "core1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.core1_prefix, "-")
  location        = local.core1_location
  storage_account = azurerm_storage_account.region1

  private_dns_zone = local.core1_dns_zone
  dns_zone_linked_vnets = {
    "hub" = { vnet = module.hub.vnet.id, registration_enabled = false }
  }
  dns_zone_linked_rulesets = {
    "hub" = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub_onprem.id
  }

  nsg_config = {
    "${local.core1_prefix}main"  = azurerm_network_security_group.nsg_region1_main.id
    "${local.core1_prefix}appgw" = azurerm_network_security_group.nsg_region1_appgw.id
    "${local.core1_prefix}ilb"   = azurerm_network_security_group.nsg_region1_default.id
  }

  vnet_config = [
    {
      address_space       = local.core1_address_space
      subnets             = local.core1_subnets
      subnets_nat_gateway = ["${local.core1_prefix}main", ]
      enable_ergw         = true
    }
  ]

  vm_config = [
    {
      name             = local.core1_vm_dns_host
      subnet           = "${local.core1_prefix}main"
      private_ip       = local.core1_vm_addr
      custom_data      = base64encode(local.vm_startup)
      source_image     = "ubuntu"
      dns_servers      = [local.hub_dns_in_ip, ]
      use_vm_extension = false
      delay_creation   = "60s"
    }
  ]
}

####################################################
# core2
####################################################

# base

module "core2" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.core2_prefix, "-")
  location        = local.core2_location
  storage_account = azurerm_storage_account.region1

  private_dns_zone = local.core2_dns_zone
  dns_zone_linked_vnets = {
    "hub" = { vnet = module.hub.vnet.id, registration_enabled = false }
  }
  dns_zone_linked_rulesets = {
    "hub" = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub_onprem.id
  }

  nsg_config = {
    "main"  = azurerm_network_security_group.nsg_region1_main.id
    "appgw" = azurerm_network_security_group.nsg_region1_appgw.id
    "ilb"   = azurerm_network_security_group.nsg_region1_default.id
  }

  vnet_config = [
    {
      address_space = local.core2_address_space
      subnets       = local.core2_subnets
    }
  ]

  vm_config = [
    {
      name           = local.core2_vm_dns_host
      subnet         = "${local.core2_prefix}main"
      private_ip     = local.core2_vm_addr
      custom_data    = base64encode(local.vm_startup)
      source_image   = "ubuntu"
      dns_servers    = [local.hub_dns_in_ip, ]
      delay_creation = "60s"
    }
  ]
}

####################################################
# yellow
####################################################

# base

module "yellow" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.yellow_prefix, "-")
  location        = local.yellow_location
  storage_account = azurerm_storage_account.region1

  private_dns_zone = local.yellow_dns_zone
  dns_zone_linked_vnets = {
    "hub" = { vnet = module.hub.vnet.id, registration_enabled = false }
  }
  dns_zone_linked_rulesets = {
    "hub" = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub_onprem.id
  }

  nsg_config = {
    "main"  = azurerm_network_security_group.nsg_region1_main.id
    "appgw" = azurerm_network_security_group.nsg_region1_appgw.id
    "ilb"   = azurerm_network_security_group.nsg_region1_default.id
  }

  vnet_config = [
    {
      address_space       = local.yellow_address_space
      subnets             = local.yellow_subnets
      subnets_nat_gateway = ["${local.yellow_prefix}main", ]
    }
  ]

  vm_config = [
    {
      name           = local.yellow_vm_dns_host
      subnet         = "${local.yellow_prefix}main"
      private_ip     = local.yellow_vm_addr
      custom_data    = base64encode(local.vm_startup)
      source_image   = "ubuntu"
      dns_servers    = [local.hub_dns_in_ip, ]
      delay_creation = "60s"
    }
  ]
}
