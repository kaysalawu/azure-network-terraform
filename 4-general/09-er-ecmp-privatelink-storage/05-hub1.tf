
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

locals {
  hub1_vm_init = templatefile("./scripts/server.sh", {
    USER_ASSIGNED_ID          = azurerm_user_assigned_identity.machine.id
    TARGETS                   = []
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
    ENABLE_TRAFFIC_GEN        = false
    ENABLE_IPERF3_SERVER      = true
    ENABLE_IPERF3_CLIENT      = false
    IPERF3_SERVER_IP          = ""
  })
}

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

  log_analytics_workspace_name = module.common.log_analytics_workspaces["region1"].name
  flow_log_nsg_ids = [
    module.common.nsg_main["region1"].id,
  ]
  network_watcher_name           = "NetworkWatcher_${local.region1}"
  network_watcher_resource_group = "NetworkWatcherRG"

  create_private_dns_zone = true
  private_dns_zone_name   = local.hub1_dns_zone
  private_dns_zone_linked_external_vnets = {
  }
  vnets_linked_to_ruleset = {
  }

  nsg_subnet_map = {
    "MainSubnet"                = module.common.nsg_main["region1"].id
    "UntrustSubnet"             = module.common.nsg_open["region1"].id
    "TrustSubnet"               = module.common.nsg_main["region1"].id
    "ManagementSubnet"          = module.common.nsg_main["region1"].id
    "AppGatewaySubnet"          = module.common.nsg_lb["region1"].id
    "LoadBalancerSubnet"        = module.common.nsg_default["region1"].id
    "PrivateLinkServiceSubnet"  = module.common.nsg_default["region1"].id
    "PrivateEndpointSubnet"     = module.common.nsg_default["region1"].id
    "AppServiceSubnet"          = module.common.nsg_default["region1"].id
    "DnsResolverInboundSubnet"  = module.common.nsg_default["region1"].id
    "DnsResolverOutboundSubnet" = module.common.nsg_default["region1"].id
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

####################################################
# workload
####################################################

module "hub1_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.hub1_prefix}vm"
  computer_name   = "vm"
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.hub1_vm_init)
  identity_ids    = [azurerm_user_assigned_identity.machine.id, ]
  tags            = local.hub1_tags

  enable_ip_forwarding = true
  interfaces = [
    {
      name               = "${local.hub1_prefix}vm-main-nic"
      subnet_id          = module.hub1.subnets["MainSubnet"].id
      private_ip_address = local.hub1_vm_addr
      create_public_ip   = true
    },
  ]
  depends_on = [
    module.hub1
  ]
}
