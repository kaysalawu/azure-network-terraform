
/*
Overview
--------
This template creates hub2 vnet from the base module.
Extra configs defined in local variable "hub2_features" of "main.tf" to enable:
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

module "hub2" {
  source             = "../../modules/base"
  resource_group     = azurerm_resource_group.rg.name
  prefix             = trimsuffix(local.hub2_prefix, "-")
  env                = "prod"
  location           = local.hub2_location
  storage_account    = module.common.storage_accounts["region2"]
  enable_diagnostics = local.enable_diagnostics
  tags               = local.hub2_tags

  log_analytics_workspace_name = module.common.log_analytics_workspaces["region2"].name
  # flow_log_nsg_ids = [
  #   module.common.nsg_main["region2"].id,
  # ]
  # network_watcher_name           = "NetworkWatcher_${local.region2}"
  # network_watcher_resource_group = "NetworkWatcherRG"

  create_private_dns_zone = true
  private_dns_zone_name   = local.hub2_dns_zone
  private_dns_zone_linked_external_vnets = {
    "spoke4" = module.spoke4.vnet.id
    "spoke5" = module.spoke5.vnet.id
  }
  vnets_linked_to_ruleset = {
    "spoke4" = module.spoke4.vnet.id
    "spoke5" = module.spoke5.vnet.id
  }

  nsg_subnet_map = {
    "MainSubnet"                = module.common.nsg_main["region2"].id
    "UntrustSubnet"             = module.common.nsg_open["region2"].id
    "TrustSubnet"               = module.common.nsg_main["region2"].id
    "ManagementSubnet"          = module.common.nsg_main["region2"].id
    "AppGatewaySubnet"          = module.common.nsg_lb["region2"].id
    "LoadBalancerSubnet"        = module.common.nsg_default["region2"].id
    "PrivateLinkServiceSubnet"  = module.common.nsg_default["region2"].id
    "PrivateEndpointSubnet"     = module.common.nsg_default["region2"].id
    "AppServiceSubnet"          = module.common.nsg_default["region2"].id
    "DnsResolverInboundSubnet"  = module.common.nsg_default["region2"].id
    "DnsResolverOutboundSubnet" = module.common.nsg_default["region2"].id
  }

  config_vnet      = local.hub2_features.config_vnet
  config_s2s_vpngw = local.hub2_features.config_s2s_vpngw
  config_p2s_vpngw = local.hub2_features.config_p2s_vpngw
  config_ergw      = local.hub2_features.config_ergw
  config_firewall  = local.hub2_features.config_firewall
  config_nva       = local.hub2_features.config_nva

  depends_on = [
    module.common,
  ]
}

####################################################
# workload
####################################################

module "hub2_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.hub2_prefix}vm"
  computer_name   = "vm"
  location        = local.hub2_location
  storage_account = module.common.storage_accounts["region2"]
  custom_data     = base64encode(local.vm_startup)
  identity_ids    = [azurerm_user_assigned_identity.machine.id, ]
  tags            = local.hub2_tags

  enable_ip_forwarding = true
  interfaces = [
    {
      name               = "${local.hub2_prefix}vm-main-nic"
      subnet_id          = module.hub2.subnets["MainSubnet"].id
      private_ip_address = local.hub2_vm_addr
      create_public_ip   = true
    },
  ]
  depends_on = [
    module.hub2
  ]
}
