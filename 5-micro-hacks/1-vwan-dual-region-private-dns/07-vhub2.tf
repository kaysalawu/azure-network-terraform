
####################################################
# virtual hub
####################################################

module "vhub2" {
  source         = "../../modules/virtual-hub"
  prefix         = trimsuffix(local.vhub2_prefix, "-")
  resource_group = azurerm_resource_group.rg.name
  location       = local.vhub2_location
  virtual_wan_id = azurerm_virtual_wan.vwan.id
  address_prefix = local.vhub2_address_prefix

  s2s_vpn_gateway = local.vhub2_features.s2s_vpn_gateway
}

data "azurerm_virtual_hub_route_table" "vhub2_default" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "defaultRouteTable"
  virtual_hub_name    = module.vhub2.virtual_hub.name
  depends_on          = [module.vhub2]
}

data "azurerm_virtual_hub_route_table" "vhub2_none" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "noneRouteTable"
  virtual_hub_name    = module.vhub2.virtual_hub.name
  depends_on          = [module.vhub2]
}
