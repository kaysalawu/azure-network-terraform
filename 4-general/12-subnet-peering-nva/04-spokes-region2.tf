
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

  enable_diagnostics             = local.enable_diagnostics
  enable_ipv6                    = local.enable_ipv6
  log_analytics_workspace_name   = module.common.log_analytics_workspaces["region2"].name
  network_watcher_name           = "NetworkWatcher_${local.region2}"
  network_watcher_resource_group = "NetworkWatcherRG"

  dns_zones_linked_to_vnet = [
    { name = module.common.private_dns_zones[local.region2_dns_zone].name, registration_enabled = true },
  ]

  nsg_subnet_map = {
    "MainSubnet"               = module.common.nsg_main["region2"].id
    "UntrustSubnet"            = module.common.nsg_nva["region2"].id
    "TrustSubnet"              = module.common.nsg_main["region2"].id
    "ManagementSubnet"         = module.common.nsg_main["region2"].id
    "AppGatewaySubnet"         = module.common.nsg_lb["region2"].id
    "LoadBalancerSubnet"       = module.common.nsg_default["region2"].id
    "PrivateLinkServiceSubnet" = module.common.nsg_default["region2"].id
    "PrivateEndpointSubnet"    = module.common.nsg_default["region2"].id
    "AppServiceSubnet"         = module.common.nsg_default["region2"].id
    "TestSubnet"               = module.common.nsg_main["region2"].id
  }

  config_vnet = {
    bgp_community = local.spoke4_bgp_community
    address_space = local.spoke4_address_space
    subnets       = local.spoke4_subnets
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

resource "time_sleep" "spoke4" {
  create_duration = "90s"
  depends_on = [
    module.spoke4
  ]
}

# workload

module "spoke4_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.spoke4_vm_hostname}"
  computer_name   = local.spoke4_vm_hostname
  location        = local.spoke4_location
  storage_account = module.common.storage_accounts["region2"]
  custom_data     = base64encode(module.probe_vm_cloud_init.cloud_config)
  tags            = local.spoke4_tags

  enable_ipv6 = local.enable_ipv6
  interfaces = [
    {
      name                 = "${local.spoke4_prefix}vm-main-nic"
      subnet_id            = module.spoke4.subnets["MainSubnet"].id
      private_ip_address   = local.spoke4_vm_addr
      private_ipv6_address = local.spoke4_vm_addr_v6
    },
  ]
  depends_on = [
    time_sleep.spoke4,
  ]
}

####################################################
# output files
####################################################

locals {
  spokes_region2_files = {
  }
}

resource "local_file" "spokes_region2_files" {
  for_each = local.spokes_region2_files
  filename = each.key
  content  = each.value
}
