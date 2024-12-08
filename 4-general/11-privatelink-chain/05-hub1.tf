
####################################################
# vnet
####################################################

# base

module "hub1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.hub1_prefix, "-")
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.hub1_tags

  enable_diagnostics           = local.enable_diagnostics
  enable_ipv6                  = local.enable_ipv6
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
  }

  config_vnet = local.hub1_features.config_vnet

  depends_on = [
    module.common,
  ]
}

resource "time_sleep" "hub1" {
  create_duration = "90s"
  depends_on = [
    module.hub1
  ]
}

####################################################
# workload
####################################################

module "hub1_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.hub1_vm_hostname}"
  computer_name   = local.hub1_vm_hostname
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.vm_cloud_init.cloud_config)
  tags            = local.hub1_tags

  enable_ipv6 = local.enable_ipv6
  interfaces = [
    {
      name                 = "${local.hub1_prefix}vm-main-nic"
      subnet_id            = module.hub1.subnets["MainSubnet"].id
      private_ip_address   = local.hub1_vm_addr
      private_ipv6_address = local.hub1_vm_addr_v6
      create_public_ip     = true
    },
  ]
  depends_on = [
    time_sleep.hub1,
  ]
}
