
####################################################
# vnet
####################################################

module "ecs" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.ecs_prefix, "-")
  env             = "prod"
  location        = local.ecs_location
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.ecs_tags

  enable_diagnostics           = local.enable_diagnostics
  log_analytics_workspace_name = module.common.log_analytics_workspaces["region1"].name

  nsg_subnet_map = {
    "PublicSubnet"     = module.common.nsg_main["region1"].id
    "ProductionSubnet" = module.common.nsg_main["region1"].id
    "UntrustSubnet"    = module.common.nsg_main["region1"].id
    "AppGatewaySubnet" = module.common.nsg_lb["region1"].id
  }

  config_vnet      = local.ecs_features.config_vnet
  config_s2s_vpngw = local.ecs_features.config_s2s_vpngw
  config_p2s_vpngw = local.ecs_features.config_p2s_vpngw
  config_ergw      = local.ecs_features.config_ergw
  config_firewall  = local.ecs_features.config_firewall
  config_nva       = local.ecs_features.config_nva

  depends_on = [
    module.common,
  ]
}
