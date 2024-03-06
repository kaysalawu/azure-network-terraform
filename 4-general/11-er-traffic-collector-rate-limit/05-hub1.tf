
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
  hub1_vnet_flow_logs = templatefile("./scripts/vnet-flow-logs.sh", {
    LOCATION             = local.hub1_location
    RESOURCE_GROUP       = azurerm_resource_group.rg.name
    NAME                 = "${local.hub1_prefix}vnet-flow-logs"
    VNET_NAME            = module.hub1.vnet.name
    STORAGE_ACCOUNT_NAME = module.common.storage_accounts["region1"].name
    WORKSPACE_ID         = module.common.log_analytics_workspaces["region1"].workspace_id
  })
}

####################################################
# vnet
####################################################

module "hub1" {
  source            = "../../modules/base"
  resource_group    = azurerm_resource_group.rg.name
  prefix            = trimsuffix(local.hub1_prefix, "-")
  env               = "prod"
  location          = local.hub1_location
  storage_account   = module.common.storage_accounts["region1"]
  user_assigned_ids = [azurerm_user_assigned_identity.machine.id, ]
  tags              = local.hub1_tags

  enable_diagnostics           = local.enable_diagnostics
  log_analytics_workspace_name = module.common.log_analytics_workspaces["region1"].name
  # flow_log_nsg_ids = [
  #   module.common.nsg_main["region1"].id,
  # ]
  # network_watcher_name           = "NetworkWatcher_${local.region1}"
  # network_watcher_resource_group = "NetworkWatcherRG"

  dns_zones_linked_to_vnet = [
    { name = module.common.private_dns_zones[local.region1_dns_zone].name, registration_enabled = true },
    { name = azurerm_private_dns_zone.privatelink_blob.name },
    { name = azurerm_private_dns_zone.privatelink_appservice.name },
  ]

  vnets_linked_to_ruleset = [
    { name = "hub1", vnet_id = module.hub1.vnet.id },
  ]

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
  name            = "${local.prefix}-${local.hub1_vm_hostname}"
  computer_name   = local.hub1_vm_hostname
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.vm_startup)
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

####################################################
# output files
####################################################

locals {
  hub1_files = {
    "output/vnet-flow-logs.sh" = local.hub1_vnet_flow_logs
  }
}

resource "local_file" "hub1_files" {
  for_each = local.branch1_files
  filename = each.key
  content  = each.value
}
