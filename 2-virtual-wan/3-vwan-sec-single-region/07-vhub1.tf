
module "vhub1" {
  source         = "../../modules/virtual-hub"
  prefix         = local.vhub1_prefix
  resource_group = azurerm_resource_group.rg.name
  location       = local.vhub1_location
  virtual_wan_id = azurerm_virtual_wan.vwan.id
  address_prefix = local.vhub1_address_prefix

  storage_account_id         = module.common.storage_accounts["region1"].id
  log_analytics_workspace_id = module.common.analytics_workspaces["region1"].id

  enable_er_gateway      = local.vhub1_features.enable_er_gateway
  enable_s2s_vpn_gateway = local.vhub1_features.enable_s2s_vpn_gateway
  enable_p2s_vpn_gateway = local.vhub1_features.enable_p2s_vpn_gateway

  bgp_config = [
    {
      asn                   = local.vhub1_bgp_asn
      instance_0_custom_ips = [local.vhub1_vpngw_bgp_apipa_0]
      instance_1_custom_ips = [local.vhub1_vpngw_bgp_apipa_1]
    }
  ]

  security_config = [
    {
      enable_firewall    = local.vhub1_features.security.enable_firewall
      firewall_sku       = local.vhub1_features.security.firewall_sku
      firewall_policy_id = local.vhub1_features.security.firewall_policy_id
    }
  ]
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

resource "azurerm_virtual_hub_route_table" "vhub1_custom" {
  count          = local.vhub1_features.security.use_routing_intent ? 0 : 1
  name           = "custom"
  virtual_hub_id = module.vhub1.virtual_hub.id
  labels         = ["custom"]
}
