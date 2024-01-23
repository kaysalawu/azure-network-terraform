
/*
Overview
--------
This template creates the spoke vnets from the base module.
It also deploys a simple web server VM in each spoke.
Spoke1 VM is configured to generate traffic to selected targets.
Private DNS zones are created for each spoke and linked to the hub vnet.
NSGs are assigned to selected subnets.
*/

####################################################
# spoke1
####################################################

# base

module "spoke1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.spoke1_prefix, "-")
  env             = "prod"
  location        = local.spoke1_location
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.spoke1_tags

  create_private_dns_zone = true
  private_dns_zone_name   = local.spoke1_dns_zone
  private_dns_zone_linked_external_vnets = {
    "hub1" = module.hub1.vnet.id
  }

  nsg_subnet_map = {
    "MainSubnet"               = module.common.nsg_main["region1"].id
    "UntrustSubnet"            = module.common.nsg_open["region1"].id
    "TrustSubnet"              = module.common.nsg_main["region1"].id
    "ManagementSubnet"         = module.common.nsg_main["region1"].id
    "AppGatewaySubnet"         = module.common.nsg_lb["region1"].id
    "LoadBalancerSubnet"       = module.common.nsg_default["region1"].id
    "PrivateLinkServiceSubnet" = module.common.nsg_default["region1"].id
    "PrivateEndpointSubnet"    = module.common.nsg_default["region1"].id
    "AppServiceSubnet"         = module.common.nsg_default["region1"].id
  }

  config_vnet = {
    address_space = local.spoke1_address_space
    subnets       = local.spoke1_subnets
    nat_gateway_subnet_names = [
      "MainSubnet",
      "UntrustSubnet",
    ]
  }
}

# workload

locals {
  spoke1_vm_init = templatefile("../../scripts/server.sh", {
    USER_ASSIGNED_ID          = azurerm_user_assigned_identity.machine.id
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
    ENABLE_TRAFFIC_GEN        = true
  })
}

module "spoke1_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.spoke1_prefix}vm"
  computer_name   = "vm"
  location        = local.spoke1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.spoke1_vm_init)
  tags            = local.spoke1_tags

  interfaces = [
    {
      name               = "${local.spoke1_prefix}vm-main"
      subnet_id          = module.spoke1.subnets["MainSubnet"].id
      private_ip_address = local.spoke1_vm_addr
    },
  ]
  depends_on = [module.spoke1]
}

####################################################
# spoke2
####################################################

# base

module "spoke2" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.spoke2_prefix, "-")
  env             = "prod"
  location        = local.spoke2_location
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.spoke2_tags

  create_private_dns_zone = true
  private_dns_zone_name   = local.spoke2_dns_zone
  private_dns_zone_linked_external_vnets = {
    "hub1" = module.hub1.vnet.id
  }

  nsg_subnet_map = {
    "MainSubnet"               = module.common.nsg_main["region1"].id
    "UntrustSubnet"            = module.common.nsg_open["region1"].id
    "TrustSubnet"              = module.common.nsg_main["region1"].id
    "ManagementSubnet"         = module.common.nsg_main["region1"].id
    "AppGatewaySubnet"         = module.common.nsg_lb["region1"].id
    "LoadBalancerSubnet"       = module.common.nsg_default["region1"].id
    "PrivateLinkServiceSubnet" = module.common.nsg_default["region1"].id
    "PrivateEndpointSubnet"    = module.common.nsg_default["region1"].id
    "AppServiceSubnet"         = module.common.nsg_default["region1"].id
  }

  config_vnet = {
    address_space = local.spoke2_address_space
    subnets       = local.spoke2_subnets
    nat_gateway_subnet_names = [
      "MainSubnet",
      "UntrustSubnet",
    ]
  }
}

# workload

module "spoke2_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.spoke2_prefix}vm"
  computer_name   = "vm"
  location        = local.spoke2_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.vm_startup)
  tags            = local.spoke2_tags

  interfaces = [
    {
      name               = "${local.spoke2_prefix}vm-main"
      subnet_id          = module.spoke2.subnets["MainSubnet"].id
      private_ip_address = local.spoke2_vm_addr
    },
  ]
  depends_on = [module.spoke2]
}

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
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.spoke3_tags

  create_private_dns_zone = true
  private_dns_zone_name   = local.spoke3_dns_zone
  private_dns_zone_linked_external_vnets = {
    "hub1" = module.hub1.vnet.id
  }

  nsg_subnet_map = {
    "MainSubnet"               = module.common.nsg_main["region1"].id
    "UntrustSubnet"            = module.common.nsg_open["region1"].id
    "TrustSubnet"              = module.common.nsg_main["region1"].id
    "ManagementSubnet"         = module.common.nsg_main["region1"].id
    "AppGatewaySubnet"         = module.common.nsg_lb["region1"].id
    "LoadBalancerSubnet"       = module.common.nsg_default["region1"].id
    "PrivateLinkServiceSubnet" = module.common.nsg_default["region1"].id
    "PrivateEndpointSubnet"    = module.common.nsg_default["region1"].id
    "AppServiceSubnet"         = module.common.nsg_default["region1"].id
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

module "spoke3_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.spoke3_prefix, "-")
  name            = "${local.spoke3_prefix}vm"
  computer_name   = "vm"
  location        = local.spoke3_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.vm_startup)
  tags            = local.spoke3_tags

  interfaces = [
    {
      name               = "${local.spoke3_prefix}vm-main"
      subnet_id          = module.spoke3.subnets["MainSubnet"].id
      private_ip_address = local.spoke3_vm_addr
    },
  ]
  depends_on = [module.spoke3]
}

