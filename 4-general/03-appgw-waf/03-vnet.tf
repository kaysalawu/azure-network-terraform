
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

  enable_diagnostics           = local.enable_diagnostics
  log_analytics_workspace_name = module.common.log_analytics_workspaces["region1"].name

  nsg_subnet_map = {
    "MainSubnet"                = module.common.nsg_main["region1"].id
    "UntrustSubnet"             = module.common.nsg_nva["region1"].id
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
