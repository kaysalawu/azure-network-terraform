
####################################################
# spoke4
####################################################

# base

module "spoke4" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.spoke4_prefix, "-")
  env             = "prod"
  location        = local.spoke4_location
  storage_account = module.common.storage_accounts["region2"]
  tags = {
    "nodeType" = "spoke"
    "env"      = "prod"
  }

  create_private_dns_zone = true
  private_dns_zone_name   = "spoke4.${local.cloud_domain}"
  private_dns_zone_linked_external_vnets = {
    "hub2" = module.hub2.vnet.id
  }

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

  vnet_config = [
    {
      address_space = local.spoke4_address_space
      subnets       = local.spoke4_subnets
    }
  ]
}

# workload

module "spoke4_vm" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.spoke4_prefix
  name                  = "vm"
  location              = local.spoke4_location
  subnet                = module.spoke4.subnets["MainSubnet"].id
  private_ip            = local.spoke4_vm_addr
  enable_public_ip      = true
  custom_data           = base64encode(local.vm_startup)
  storage_account       = module.common.storage_accounts["region2"]
  private_dns_zone_name = "spoke4.${local.cloud_domain}"
  delay_creation        = "1m"
  tags                  = local.spoke4_tags
  depends_on            = [module.spoke4]
}

####################################################
# spoke5
####################################################

# base

module "spoke5" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.spoke5_prefix, "-")
  env             = "prod"
  location        = local.spoke5_location
  storage_account = module.common.storage_accounts["region2"]
  tags = {
    "nodeType" = "spoke"
    "env"      = "prod"
  }

  create_private_dns_zone = true
  private_dns_zone_name   = "spoke5.${local.cloud_domain}"
  private_dns_zone_linked_external_vnets = {
    "hub2" = module.hub2.vnet.id
  }

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

  vnet_config = [
    {
      address_space = local.spoke5_address_space
      subnets       = local.spoke5_subnets
    }
  ]
}

# workload

module "spoke5_vm" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.spoke5_prefix
  name                  = "vm"
  location              = local.spoke5_location
  subnet                = module.spoke5.subnets["MainSubnet"].id
  private_ip            = local.spoke5_vm_addr
  enable_public_ip      = true
  custom_data           = base64encode(local.vm_startup)
  storage_account       = module.common.storage_accounts["region2"]
  private_dns_zone_name = "spoke5.${local.cloud_domain}"
  delay_creation        = "1m"
  tags                  = local.spoke5_tags
  depends_on            = [module.spoke5]
}

####################################################
# spoke6
####################################################

# base

module "spoke6" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.spoke6_prefix, "-")
  env             = "prod"
  location        = local.spoke6_location
  storage_account = module.common.storage_accounts["region2"]
  tags = {
    "env" = "prod"
  }

  create_private_dns_zone = true
  private_dns_zone_name   = "spoke6.${local.cloud_domain}"
  private_dns_zone_linked_external_vnets = {
    "hub2" = module.hub2.vnet.id
  }

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

  vnet_config = [
    {
      address_space = local.spoke6_address_space
      subnets       = local.spoke6_subnets
    }
  ]
}

# workload

module "spoke6_vm" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.spoke6_prefix
  name                  = "vm"
  location              = local.spoke6_location
  subnet                = module.spoke6.subnets["MainSubnet"].id
  private_ip            = local.spoke6_vm_addr
  enable_public_ip      = true
  custom_data           = base64encode(local.vm_startup)
  storage_account       = module.common.storage_accounts["region2"]
  private_dns_zone_name = "spoke6.${local.cloud_domain}"
  delay_creation        = "1m"
  tags                  = local.spoke6_tags
  depends_on            = [module.spoke6]
}
