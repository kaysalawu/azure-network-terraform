
/*
Overview
--------
This template creates the spoke vnets from the base module.
It also deploys a simple web server VM in each spoke.
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

  enable_diagnostics           = local.enable_diagnostics
  log_analytics_workspace_name = module.common.log_analytics_workspaces["region2"].name

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
  }

  config_vnet = {
    address_space = local.spoke4_address_space
    subnets       = local.spoke4_subnets
    nat_gateway_subnet_names = [
      "MainSubnet",
      "UntrustSubnet",
    ]
  }
  depends_on = [
    module.common,
  ]
}

resource "time_sleep" "spoke4" {
  create_duration = "60s"
  depends_on = [
    module.spoke4
  ]
}

# workload

locals {
  spoke4_vm_init = templatefile("../../scripts/server.sh", {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
  })
}

module "spoke4_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.spoke4_vm_hostname}"
  computer_name   = local.spoke4_vm_hostname
  location        = local.spoke4_location
  storage_account = module.common.storage_accounts["region2"]
  custom_data     = base64encode(local.spoke4_vm_init)
  tags            = local.spoke4_tags

  interfaces = [
    {
      name               = "${local.spoke4_prefix}vm-main-nic"
      subnet_id          = module.spoke4.subnets["MainSubnet"].id
      private_ip_address = local.spoke4_vm_addr
    },
  ]
  depends_on = [
    time_sleep.spoke4,
  ]
}

####################################################
# spoke5
####################################################

# base

module "spoke5" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.spoke5_prefix, "-")
  env             = "prod"
  location        = local.spoke5_location
  storage_account = module.common.storage_accounts["region2"]
  tags            = local.spoke5_tags

  enable_diagnostics           = local.enable_diagnostics
  log_analytics_workspace_name = module.common.log_analytics_workspaces["region2"].name

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
  }

  config_vnet = {
    address_space = local.spoke5_address_space
    subnets       = local.spoke5_subnets
    nat_gateway_subnet_names = [
      "MainSubnet",
      "UntrustSubnet",
    ]
  }
  depends_on = [
    module.common,
  ]
}

resource "time_sleep" "spoke5" {
  create_duration = "60s"
  depends_on = [
    module.spoke5
  ]
}

# workload

module "spoke5_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.spoke5_vm_hostname}"
  computer_name   = local.spoke5_vm_hostname
  location        = local.spoke5_location
  storage_account = module.common.storage_accounts["region2"]
  custom_data     = base64encode(local.vm_startup)
  tags            = local.spoke5_tags

  interfaces = [
    {
      name               = "${local.spoke5_prefix}vm-main-nic"
      subnet_id          = module.spoke5.subnets["MainSubnet"].id
      private_ip_address = local.spoke5_vm_addr
    },
  ]
  depends_on = [
    time_sleep.spoke5,
  ]
}

####################################################
# spoke6
####################################################

# base

module "spoke6" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.spoke6_prefix, "-")
  env             = "prod"
  location        = local.spoke6_location
  storage_account = module.common.storage_accounts["region2"]
  tags            = local.spoke6_tags

  enable_diagnostics           = local.enable_diagnostics
  log_analytics_workspace_name = module.common.log_analytics_workspaces["region2"].name

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
  }

  config_vnet = {
    address_space = local.spoke6_address_space
    subnets       = local.spoke6_subnets
    nat_gateway_subnet_names = [
      "MainSubnet",
      "UntrustSubnet",
    ]
  }
  depends_on = [
    module.common,
  ]
}

resource "time_sleep" "spoke6" {
  create_duration = "60s"
  depends_on = [
    module.spoke6
  ]
}

# workload

module "spoke6_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.spoke6_vm_hostname}"
  computer_name   = local.spoke6_vm_hostname
  location        = local.spoke6_location
  storage_account = module.common.storage_accounts["region2"]
  custom_data     = base64encode(local.vm_startup)
  tags            = local.spoke6_tags

  interfaces = [
    {
      name               = "${local.spoke6_prefix}vm-main-nic"
      subnet_id          = module.spoke6.subnets["MainSubnet"].id
      private_ip_address = local.spoke6_vm_addr
    },
  ]
  depends_on = [
    time_sleep.spoke6,
  ]
}

