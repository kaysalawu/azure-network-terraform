
####################################################
# virtual hub
####################################################

module "vhub3" {
  source         = "../../modules/virtual-hub"
  prefix         = trimsuffix(local.vhub3_prefix, "-")
  resource_group = azurerm_resource_group.rg.name
  location       = local.vhub3_location
  virtual_wan_id = azurerm_virtual_wan.vwan.id
  address_prefix = local.vhub3_address_prefix

  express_route_gateway = local.vhub3_features.express_route_gateway
  s2s_vpn_gateway       = local.vhub3_features.s2s_vpn_gateway
  p2s_vpn_gateway       = local.vhub3_features.p2s_vpn_gateway

  config_security = local.vhub3_features.config_security

  enable_diagnostics           = local.enable_diagnostics
  log_analytics_workspace_name = module.common.log_analytics_workspaces["region3"].name

  depends_on = [
    module.common
  ]
}

data "azurerm_virtual_hub_route_table" "vhub3_default" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "defaultRouteTable"
  virtual_hub_name    = module.vhub3.virtual_hub.name
  depends_on          = [module.vhub3]
}

data "azurerm_virtual_hub_route_table" "vhub3_none" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "noneRouteTable"
  virtual_hub_name    = module.vhub3.virtual_hub.name
  depends_on          = [module.vhub3]
}
