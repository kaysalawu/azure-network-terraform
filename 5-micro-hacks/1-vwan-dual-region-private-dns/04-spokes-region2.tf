
/*
Overview
--------
This template creates the spoke vnets from the base module.
It also deploys a simple web server VM in each spoke.
Private DNS zones are created for each spoke and linked to the hub vnet.
NSGs are assigned to selected subnets.
*/

####################################################
# spoke3
####################################################

# base

module "spoke3" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.spoke3_prefix, "-")
  env             = "prod"
  location        = local.spoke3_location
  storage_account = module.common.storage_accounts["region2"]
  tags            = local.spoke3_tags

  # create_private_dns_zone = true
  # private_dns_zone_name   = local.spoke3_dns_zone
  # private_dns_zone_linked_external_vnets = {
  #   "shared2" = module.shared2.vnet.id
  # }

  nsg_subnet_map = {
    "MainSubnet"               = module.common.nsg_main["region2"].id
    "UntrustSubnet"            = module.common.nsg_open["region2"].id
    "TrustSubnet"              = module.common.nsg_main["region2"].id
    "ManagementSubnet"         = module.common.nsg_main["region2"].id
    "AppGatewaySubnet"         = module.common.nsg_lb["region2"].id
    "LoadBalancerSubnet"       = module.common.nsg_default["region2"].id
    "PrivateLinkServiceSubnet" = module.common.nsg_default["region2"].id
    "PrivateEndpointSubnet"    = module.common.nsg_default["region2"].id
    "AppServiceSubnet"         = module.common.nsg_default["region2"].id
  }

  config_vnet = {
    address_space = local.spoke3_address_space
    subnets       = local.spoke3_subnets
    nat_gateway_subnet_names = [
      "MainSubnet",
      "UntrustSubnet",
    ]
  }
}

# workload

locals {
  spoke3_vm_init = templatefile("../../scripts/server.sh", {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
    ENABLE_TRAFFIC_GEN        = true
  })
}

module "spoke3_vm" {
  source          = "../../modules/linux"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = local.spoke3_prefix
  name            = "vm"
  location        = local.spoke3_location
  subnet          = module.spoke3.subnets["MainSubnet"].id
  private_ip      = local.spoke3_vm_addr
  custom_data     = base64encode(local.spoke3_vm_init)
  storage_account = module.common.storage_accounts["region2"]
  # private_dns_zone_name = local.spoke3_dns_zone
  delay_creation = "1m"
  tags           = local.spoke3_tags
  depends_on = [
    module.spoke3,
  ]
}

####################################################
# spoke4
####################################################

# base

module "spoke4" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.spoke4_prefix, "-")
  env             = "prod"
  location        = local.spoke4_location
  storage_account = module.common.storage_accounts["region2"]
  tags            = local.spoke4_tags

  # create_private_dns_zone = true
  # private_dns_zone_name   = local.spoke4_dns_zone
  # private_dns_zone_linked_external_vnets = {
  #   "shared2" = module.shared2.vnet.id
  # }

  nsg_subnet_map = {
    "MainSubnet"               = module.common.nsg_main["region2"].id
    "UntrustSubnet"            = module.common.nsg_open["region2"].id
    "TrustSubnet"              = module.common.nsg_main["region2"].id
    "ManagementSubnet"         = module.common.nsg_main["region2"].id
    "AppGatewaySubnet"         = module.common.nsg_lb["region2"].id
    "LoadBalancerSubnet"       = module.common.nsg_default["region2"].id
    "PrivateLinkServiceSubnet" = module.common.nsg_default["region2"].id
    "PrivateEndpointSubnet"    = module.common.nsg_default["region2"].id
    "AppServiceSubnet"         = module.common.nsg_default["region2"].id
  }

  config_vnet = {
    address_space = local.spoke4_address_space
    subnets       = local.spoke4_subnets
    nat_gateway_subnet_names = [
      "MainSubnet",
      "UntrustSubnet",
    ]
  }
}

# workload

module "spoke4_vm" {
  source          = "../../modules/linux"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = local.spoke4_prefix
  name            = "vm"
  location        = local.spoke4_location
  subnet          = module.spoke4.subnets["MainSubnet"].id
  private_ip      = local.spoke4_vm_addr
  custom_data     = base64encode(local.vm_startup)
  storage_account = module.common.storage_accounts["region2"]
  # private_dns_zone_name = local.spoke4_dns_zone
  delay_creation = "1m"
  tags           = local.spoke4_tags
  depends_on = [
    module.spoke2,
  ]
}
