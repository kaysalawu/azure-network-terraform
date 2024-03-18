
####################################################
# virtual hub
####################################################

module "vhub1" {
  source         = "../../modules/virtual-hub"
  prefix         = trimsuffix(local.vhub1_prefix, "-")
  resource_group = azurerm_resource_group.rg.name
  location       = local.vhub1_location
  virtual_wan_id = azurerm_virtual_wan.vwan.id
  address_prefix = local.vhub1_address_prefix

  s2s_vpn_gateway = local.vhub1_features.s2s_vpn_gateway
}

data "azurerm_virtual_hub_route_table" "vhub1_default" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "defaultRouteTable"
  virtual_hub_name    = module.vhub1.virtual_hub.name
  depends_on          = [module.vhub1]
}

data "azurerm_virtual_hub_route_table" "vhub1_none" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "noneRouteTable"
  virtual_hub_name    = module.vhub1.virtual_hub.name
  depends_on          = [module.vhub1]
}
