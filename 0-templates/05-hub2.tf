
####################################################
# vnet
####################################################

module "hub2" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.hub2_prefix, "-")
  env             = "prod"
  location        = local.hub2_location
  storage_account = module.common.storage_accounts["region2"]
  tags = {
    "nodeType" = "hub"
    "env"      = "prod"
  }

  create_private_dns_zone = true
  private_dns_zone_name   = "hub2.${local.cloud_domain}"
  private_dns_zone_linked_external_vnets = {
    "spoke4" = module.spoke4.vnet.id
    "spoke5" = module.spoke5.vnet.id
  }

  nsg_subnet_map = {
    "MainSubnet"                = module.common.nsg_main["region2"].id
    "NvaSubnet"                 = module.common.nsg_nva["region2"].id
    "LoadBalancerSubnet"        = module.common.nsg_default["region2"].id
    "PrivateLinkServiceSubnet"  = module.common.nsg_default["region2"].id
    "PrivateEndpointSubnet"     = module.common.nsg_default["region2"].id
    "DnsResolverInboundSubnet"  = module.common.nsg_default["region2"].id
    "DnsResolverOutboundSubnet" = module.common.nsg_default["region2"].id
    "AppServiceSubnet"          = module.common.nsg_default["region2"].id
  }

  vnet_config     = local.hub2_features.vnet_config
  firewall_config = local.hub2_features.firewall_config
  nva_config      = local.hub2_features.nva_config
}

####################################################
# workload
####################################################

module "hub2_vm" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.hub2_prefix
  name                  = "vm"
  location              = local.hub2_location
  subnet                = module.hub2.subnets["MainSubnet"].id
  private_ip            = local.hub2_vm_addr
  enable_public_ip      = true
  custom_data           = base64encode(local.vm_startup)
  storage_account       = module.common.storage_accounts["region2"]
  private_dns_zone_name = "hub2.${local.cloud_domain}"
  delay_creation        = "2m"
  tags                  = local.hub2_tags
  depends_on = [
    module.hub2,
  ]
}
