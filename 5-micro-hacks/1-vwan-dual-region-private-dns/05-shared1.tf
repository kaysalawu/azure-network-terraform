
/*
Overview
--------
This template creates shared1 vnet from the base module.
Extra configs defined in local variable "shared1_features" of "main.tf" to enable:
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

module "shared1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.shared1_prefix, "-")
  env             = "prod"
  location        = local.shared1_location
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.shared1_tags

  # create_private_dns_zone = true
  # private_dns_zone_name   = local.shared1_dns_zone
  # private_dns_zone_linked_external_vnets = {
  #   "spoke1" = module.spoke1.vnet.id
  #   "spoke2" = module.spoke2.vnet.id
  # }
  # private_dns_ruleset_linked_external_vnets = {
  #   "spoke1" = module.spoke1.vnet.id
  #   "spoke2" = module.spoke2.vnet.id
  # }

  nsg_subnet_map = {
    "MainSubnet"               = module.common.nsg_main["region1"].id
    "UntrustSubnet"            = module.common.nsg_open["region1"].id
    "TrustSubnet"              = module.common.nsg_main["region1"].id
    "ManagementSubnet"         = module.common.nsg_main["region1"].id
    "AppGatewaySubnet"         = module.common.nsg_lb["region1"].id
    "LoadBalancerSubnet"       = module.common.nsg_default["region1"].id
    "PrivateLinkServiceSubnet" = module.common.nsg_default["region1"].id
    "PrivateEndpointSubnet"    = module.common.nsg_default["region1"].id
    "AppServiceSubnet"         = module.common.nsg_default["region1"].id
  }

  config_vnet = local.shared1_features.config_vnet
}
