
####################################################
# spoke1
####################################################

# base

module "spoke1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.spoke1_prefix, "-")
  env             = "prod"
  location        = local.spoke1_location
  storage_account = module.common.storage_accounts["region1"]
  tags = {
    "nodeType" = "spoke"
    "env"      = "prod"
  }

  create_private_dns_zone = true
  private_dns_zone_name   = local.spoke1_dns_zone
  private_dns_zone_linked_external_vnets = {
    "hub1" = module.hub1.vnet.id
  }

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

  config_vnet = {
    address_space = local.spoke1_address_space
    subnets       = local.spoke1_subnets
  }
}

# workload

locals {
  spoke1_vm_init = templatefile("../../scripts/server.sh", {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
    ENABLE_TRAFFIC_GEN        = true
  })
}

module "spoke1_vm" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.spoke1_prefix
  name                  = "vm"
  location              = local.spoke1_location
  subnet                = module.spoke1.subnets["MainSubnet"].id
  private_ip            = local.spoke1_vm_addr
  enable_public_ip      = true
  custom_data           = base64encode(local.spoke1_vm_init)
  storage_account       = module.common.storage_accounts["region1"]
  private_dns_zone_name = local.spoke1_dns_zone
  delay_creation        = "1m"
  tags                  = local.spoke1_tags
  depends_on            = [module.spoke1]
}

####################################################
# backends
####################################################

module "spoke1_be1" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.spoke1_prefix
  name                  = "be1"
  location              = local.spoke1_location
  subnet                = module.spoke1.subnets["MainSubnet"].id
  private_ip            = local.spoke1_be1_addr
  enable_public_ip      = true
  custom_data           = base64encode(local.vm_startup)
  storage_account       = module.common.storage_accounts["region1"]
  private_dns_zone_name = "spoke1.${local.cloud_domain}"
  tags                  = local.spoke1_tags
}

module "spoke1_be2" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.spoke1_prefix
  name                  = "be2"
  location              = local.spoke1_location
  subnet                = module.spoke1.subnets["MainSubnet"].id
  private_ip            = local.spoke1_be2_addr
  enable_public_ip      = true
  custom_data           = base64encode(local.vm_startup)
  storage_account       = module.common.storage_accounts["region1"]
  private_dns_zone_name = "spoke1.${local.cloud_domain}"
  tags                  = local.spoke1_tags
}

