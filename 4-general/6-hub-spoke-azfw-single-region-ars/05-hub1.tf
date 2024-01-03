
/*
Overview
--------
This template creates hub1 vnet from the base module.
Extra configs defined in local variable "hub1_features" of "main.tf" to enable:
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

module "hub1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.hub1_prefix, "-")
  env             = "prod"
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.hub1_tags

  create_private_dns_zone = true
  private_dns_zone_name   = local.hub1_dns_zone
  private_dns_zone_linked_external_vnets = {
    "spoke1" = module.spoke1.vnet.id
    "spoke2" = module.spoke2.vnet.id
  }
  private_dns_ruleset_linked_external_vnets = {
    "spoke1" = module.spoke1.vnet.id
    "spoke2" = module.spoke2.vnet.id
  }

  nsg_subnet_map = {
    "MainSubnet"                = module.common.nsg_main["region1"].id
    "UntrustSubnet"             = module.common.nsg_open["region1"].id
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

  config_vnet     = local.hub1_features.config_vnet
  config_vpngw    = local.hub1_features.config_vpngw
  config_ergw     = local.hub1_features.config_ergw
  config_firewall = local.hub1_features.config_firewall
  config_nva      = local.hub1_features.config_nva
}

####################################################
# workload
####################################################

module "hub1_vm" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.hub1_prefix
  name                  = "vm"
  location              = local.hub1_location
  subnet                = module.hub1.subnets["MainSubnet"].id
  private_ip            = local.hub1_vm_addr
  enable_public_ip      = true
  custom_data           = base64encode(local.vm_startup)
  storage_account       = module.common.storage_accounts["region1"]
  private_dns_zone_name = local.hub1_dns_zone
  tags                  = local.hub1_tags
  depends_on            = [module.hub1]
}
