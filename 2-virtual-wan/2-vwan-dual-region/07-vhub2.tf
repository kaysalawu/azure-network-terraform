
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

  er_gateway      = local.vhub2_features.er_gateway
  s2s_vpn_gateway = local.vhub2_features.s2s_vpn_gateway
  p2s_vpn_gateway = local.vhub2_features.p2s_vpn_gateway

  config_security = local.vhub2_features.config_security
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

# resource "azurerm_virtual_hub_route_table" "vhub2_custom" {
#   count          = local.vhub2_features.config_security.enable_routing_intent ? 0 : 1
#   name           = "custom"
#   virtual_hub_id = module.vhub2.virtual_hub.id
#   labels         = ["custom"]
# }
