
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
  storage_account = module.common.storage_accounts["region3"]
  tags            = local.spoke3_tags

  enable_diagnostics           = local.enable_diagnostics
  log_analytics_workspace_name = module.common.log_analytics_workspaces["region3"].name

  dns_zones_linked_to_vnet = [
    { name = module.common.private_dns_zones[local.region3_dns_zone].name, registration_enabled = true },
  ]

  nsg_subnet_map = {
    "MainSubnet"               = module.common.nsg_main["region3"].id
    "UntrustSubnet"            = module.common.nsg_open["region3"].id
    "TrustSubnet"              = module.common.nsg_main["region3"].id
    "ManagementSubnet"         = module.common.nsg_main["region3"].id
    "AppGatewaySubnet"         = module.common.nsg_lb["region3"].id
    "LoadBalancerSubnet"       = module.common.nsg_default["region3"].id
    "PrivateLinkServiceSubnet" = module.common.nsg_default["region3"].id
    "PrivateEndpointSubnet"    = module.common.nsg_default["region3"].id
    "AppServiceSubnet"         = module.common.nsg_default["region3"].id
  }

  config_vnet = {
    address_space = local.spoke3_address_space
    subnets       = local.spoke3_subnets
    nat_gateway_subnet_names = [
      "MainSubnet",
      "UntrustSubnet",
    ]
  }
  depends_on = [
    module.common,
  ]
}

# workload

locals {
  spoke3_vm_init = templatefile("../../scripts/server.sh", {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
  })
}

module "spoke3_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.spoke3_vm_hostname}"
  computer_name   = local.spoke3_vm_hostname
  location        = local.spoke3_location
  storage_account = module.common.storage_accounts["region3"]
  custom_data     = base64encode(local.spoke3_vm_init)
  tags            = local.spoke3_tags

  interfaces = [
    {
      name               = "${local.spoke3_prefix}vm-main-nic"
      subnet_id          = module.spoke3.subnets["MainSubnet"].id
      private_ip_address = local.spoke3_vm_addr
    },
  ]
  depends_on = [
    module.spoke3
  ]
}
