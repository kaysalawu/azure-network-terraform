
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

  enable_diagnostics           = local.enable_diagnostics
  log_analytics_workspace_name = module.common.log_analytics_workspaces["region1"].name

  dns_zones_linked_to_vnet = [
    { name = module.common.private_dns_zones[local.region1_dns_zone].name, registration_enabled = true },
  ]

  nsg_subnet_map = {
    "MainSubnet"               = module.common.nsg_main["region1"].id
    "UntrustSubnet"            = module.common.nsg_nva["region1"].id
    "TrustSubnet"              = module.common.nsg_main["region1"].id
    "ManagementSubnet"         = module.common.nsg_main["region1"].id
    "AppGatewaySubnet"         = module.common.nsg_lb["region1"].id
    "LoadBalancerSubnet"       = module.common.nsg_default["region1"].id
    "PrivateLinkServiceSubnet" = module.common.nsg_default["region1"].id
    "PrivateEndpointSubnet"    = module.common.nsg_default["region1"].id
    "AppServiceSubnet"         = module.common.nsg_default["region1"].id
    "TestSubnet"               = module.common.nsg_main["region1"].id
  }

  config_vnet = {
    bgp_community = local.spoke1_bgp_community
    address_space = local.spoke1_address_space
    subnets       = local.spoke1_subnets
    nat_gateway_subnet_names = [
      "MainSubnet",
      "TrustSubnet",
      "TestSubnet",
    ]
  }
  depends_on = [
    module.common,
  ]
}

resource "time_sleep" "spoke1" {
  create_duration = "90s"
  depends_on = [
    module.spoke1
  ]
}

# workload

module "spoke1_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.spoke1_vm_hostname}"
  computer_name   = local.spoke1_vm_hostname
  location        = local.spoke1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.probe_vm_cloud_init.cloud_config)
  tags            = local.spoke1_tags

  interfaces = [
    {
      name               = "${local.spoke1_prefix}vm-main-nic"
      subnet_id          = module.spoke1.subnets["MainSubnet"].id
      private_ip_address = local.spoke1_vm_addr
    },
  ]
  depends_on = [
    time_sleep.spoke1,
  ]
}

####################################################
# output files
####################################################

locals {
  spokes_region1_files = {
  }
}

resource "local_file" "spokes_region1_files" {
  for_each = local.spokes_region1_files
  filename = each.key
  content  = each.value
}
