
/*
Overview
--------
This template creates hub1 vnet from the base module.
Extra configs defined in local variable "hub1_features" of "main.tf" to enable:
  - VPN gateway, ExpressRoute gateway
  - Azure Firewall and/or NVA
  - Private DNS zone for the hub
  - Private DNS Resolver and ruleset for onprem, cloud and PrivateLink DNS resolution
It also deploys a simple web server VM in the hub.
NSGs are assigned to selected subnets.
*/

####################################################
# vnet
####################################################

module "hub1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.hub1_prefix, "-")
  env             = "prod"
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.hub1_tags

  enable_diagnostics             = local.enable_diagnostics
  log_analytics_workspace_name   = module.common.log_analytics_workspaces["region1"].name
  network_watcher_name           = "NetworkWatcher_${local.region1}"
  network_watcher_resource_group = "NetworkWatcherRG"

  dns_zones_linked_to_vnet = [
    { name = module.common.private_dns_zones[local.region1_dns_zone].name, registration_enabled = true },
    { name = azurerm_private_dns_zone.privatelink_blob.name },
    { name = azurerm_private_dns_zone.privatelink_appservice.name },
  ]

  vnets_linked_to_ruleset = [
    { name = "hub1", vnet_id = module.hub1.vnet.id },
    { name = "spoke1", vnet_id = module.spoke1.vnet.id },
  ]

  nsg_subnet_map = {
    "MainSubnet"                = module.common.nsg_main["region1"].id
    "UntrustSubnet"             = module.common.nsg_nva["region1"].id
    "TrustSubnet"               = module.common.nsg_main["region1"].id
    "ManagementSubnet"          = module.common.nsg_main["region1"].id
    "AppGatewaySubnet"          = module.common.nsg_lb["region1"].id
    "LoadBalancerSubnet"        = module.common.nsg_default["region1"].id
    "PrivateLinkServiceSubnet"  = module.common.nsg_default["region1"].id
    "PrivateEndpointSubnet"     = module.common.nsg_default["region1"].id
    "AppServiceSubnet"          = module.common.nsg_default["region1"].id
    "DnsResolverInboundSubnet"  = module.common.nsg_default["region1"].id
    "DnsResolverOutboundSubnet" = module.common.nsg_default["region1"].id
    "TestSubnet"                = module.common.nsg_main["region1"].id
  }

  config_vnet      = local.hub1_features.config_vnet
  config_s2s_vpngw = local.hub1_features.config_s2s_vpngw
  config_p2s_vpngw = local.hub1_features.config_p2s_vpngw
  config_ergw      = local.hub1_features.config_ergw
  config_firewall  = local.hub1_features.config_firewall
  config_nva       = local.hub1_features.config_nva

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

  interfaces = [
    {
      name               = "${local.hub1_prefix}vm-main-nic"
      subnet_id          = module.hub1.subnets["MainSubnet"].id
      private_ip_address = local.hub1_vm_addr
      create_public_ip   = true
    },
  ]
  depends_on = [
    time_sleep.hub1,
  ]
}
