
/*
Overview
--------
This template creates shared2 vnet from the base module.
Extra configs defined in local variable "shared2_features" of "main.tf" to enable:
  - VPN gateway, ExpressRoute gateway
  - Azure Firewall and/or NVA
  - Private DNS zone for the hub
  - Private DNS Resolver and ruleset for onprem, cloud and PrivateLink DNS resolution
It also deploys a simple web server VM in the hub.
NSGs are assigned to selected subnets.
*/

####################################################
# vnet
####################################################

module "shared2" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.shared2_prefix, "-")
  env             = "prod"
  location        = local.shared2_location
  storage_account = module.common.storage_accounts["region2"]
  tags            = local.shared2_tags

  # create_private_dns_zone = true
  # private_dns_zone_name   = local.shared2_dns_zone
  # private_dns_zone_linked_external_vnets = {
  #   "spoke3" = module.spoke3.vnet.id
  #   "spoke4" = module.spoke4.vnet.id
  # }
  # vnets_linked_to_ruleset = {
  #   "spoke3" = module.spoke3.vnet.id
  #   "spoke4" = module.spoke4.vnet.id
  # }

  nsg_subnet_map = {
    "MainSubnet"               = module.common.nsg_main["region2"].id
    "UntrustSubnet"            = module.common.nsg_open["region2"].id
    "TrustSubnet"              = module.common.nsg_main["region2"].id
    "ManagementSubnet"         = module.common.nsg_main["region2"].id
    "AppGatewaySubnet"         = module.common.nsg_lb["region2"].id
    "LoadBalancerSubnet"       = module.common.nsg_default["region2"].id
    "PrivateLinkServiceSubnet" = module.common.nsg_default["region2"].id
    "PrivateEndpointSubnet"    = module.common.nsg_default["region2"].id
    "AppServiceSubnet"         = module.common.nsg_default["region2"].id
  }

  config_vnet = local.shared2_features.config_vnet
  # config_vpngw = local.shared2_features.config_vpngw
  # config_ergw     = local.shared2_features.config_ergw
  # config_firewall = local.shared2_features.config_firewall
  # config_nva      = local.shared2_features.config_nva
}

