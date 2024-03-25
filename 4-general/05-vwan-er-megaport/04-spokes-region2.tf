
/*
Overview
--------
This template creates the spoke vnets from the base module.
It also deploys a simple web server VM in each spoke.
Private DNS zones are created for each spoke and linked to the hub vnet.
NSGs are assigned to selected subnets.
*/

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
  storage_account = module.common.storage_accounts["region2"]
  tags            = local.spoke2_tags

  enable_diagnostics           = local.enable_diagnostics
  log_analytics_workspace_name = module.common.log_analytics_workspaces["region2"].name

  dns_zones_linked_to_vnet = [
    { name = module.common.private_dns_zones[local.region2_dns_zone].name, registration_enabled = true },
  ]

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
    address_space = local.spoke2_address_space
    subnets       = local.spoke2_subnets
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
  spoke2_vm_init = templatefile("../../scripts/server.sh", {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
  })
}

module "spoke2_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.spoke2_vm_hostname}"
  computer_name   = local.spoke2_vm_hostname
  location        = local.spoke2_location
  storage_account = module.common.storage_accounts["region2"]
  custom_data     = base64encode(local.spoke2_vm_init)
  tags            = local.spoke2_tags

  interfaces = [
    {
      name               = "${local.spoke2_prefix}vm-main-nic"
      subnet_id          = module.spoke2.subnets["MainSubnet"].id
      private_ip_address = local.spoke2_vm_addr
    },
  ]
  depends_on = [
    module.spoke2
  ]
}
