
module "vhub2" {
  source         = "../../modules/virtual-hub"
  prefix         = local.vhub2_prefix
  resource_group = azurerm_resource_group.rg.name
  location       = local.vhub2_location
  virtual_wan_id = azurerm_virtual_wan.vwan.id
  address_prefix = local.vhub2_address_prefix

  storage_account_id         = module.common.storage_accounts["region2"].id
  log_analytics_workspace_id = module.common.analytics_workspaces["region2"].id

  enable_er_gateway      = local.vhub2_features.enable_er_gateway
  enable_s2s_vpn_gateway = local.vhub2_features.enable_s2s_vpn_gateway
  enable_p2s_vpn_gateway = local.vhub2_features.enable_p2s_vpn_gateway

  bgp_config = [
    {
      asn                   = local.vhub2_bgp_asn
      instance_0_custom_ips = [local.vhub2_vpngw_bgp_apipa_0]
      instance_1_custom_ips = [local.vhub2_vpngw_bgp_apipa_1]
    }
  ]

  security_config = [
    {
      create_firewall    = local.vhub2_features.security.create_firewall
      firewall_sku       = local.vhub2_features.security.firewall_sku
      firewall_policy_id = local.vhub2_features.security.firewall_policy_id
    }
  ]
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

resource "azurerm_virtual_hub_route_table" "vhub2_custom" {
  count          = local.vhub2_features.security.enable_routing_intent ? 0 : 1
  name           = "custom"
  virtual_hub_id = module.vhub2.virtual_hub.id
  labels         = ["custom"]
}
