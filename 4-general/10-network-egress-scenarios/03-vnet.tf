
####################################################
# vnet
####################################################

module "hub1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.hub1_prefix, "-")
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.hub1_tags

  enable_diagnostics                  = local.enable_diagnostics
  log_analytics_workspace_name        = module.common.log_analytics_workspaces["region1"].name
  network_watcher_name                = local.enable_vnet_flow_logs ? "NetworkWatcher_${local.region1}" : null
  network_watcher_resource_group_name = local.enable_vnet_flow_logs ? "NetworkWatcherRG" : null

  nsg_subnet_map = {
    "PublicSubnet"     = module.common.nsg_main["region1"].id
    "ProductionSubnet" = module.common.nsg_main["region1"].id
    "AppGatewaySubnet" = module.common.nsg_lb["region1"].id
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
