
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
  private_dns_zone_name   = "spoke1.${local.cloud_domain}"
  private_dns_zone_linked_external_vnets = {
    "hub1" = module.hub1.vnet.id
  }

  nsg_subnet_map = {
    "${local.spoke1_prefix}main"  = module.common.nsg_main["region1"].id
    "${local.spoke1_prefix}appgw" = module.common.nsg_appgw["region1"].id
    "${local.spoke1_prefix}ilb"   = module.common.nsg_default["region1"].id
  }

  vnet_config = [
    {
      address_space = local.spoke1_address_space
      subnets       = local.spoke1_subnets
    }
  ]

  depends_on = [
    module.common,
  ]
}

# workload

module "spoke1_vm" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.spoke1_prefix
  name                  = "vm"
  location              = local.spoke1_location
  subnet                = module.spoke1.subnets["${local.spoke1_prefix}main"].id
  private_ip            = local.spoke1_vm_addr
  custom_data           = base64encode(local.vm_startup)
  dns_servers           = [local.hub1_dns_in_addr, ]
  storage_account       = module.common.storage_accounts["region1"]
  private_dns_zone_name = "spoke1.${local.cloud_domain}"
  tags                  = local.spoke1_tags
  depends_on = [
    module.common,
    module.hub1,
  ]
}

####################################################
# spoke2
####################################################

# base

module "spoke2" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.spoke2_prefix, "-")
  env             = "prod"
  location        = local.spoke2_location
  storage_account = module.common.storage_accounts["region1"]
  tags = {
    "nodeType" = "spoke"
    "env"      = "prod"
  }

  create_private_dns_zone = true
  private_dns_zone_name   = "spoke2.${local.cloud_domain}"
  private_dns_zone_linked_external_vnets = {
    "hub1" = module.hub1.vnet.id
  }

  nsg_subnet_map = {
    "${local.spoke2_prefix}main"  = module.common.nsg_main["region1"].id
    "${local.spoke2_prefix}appgw" = module.common.nsg_appgw["region1"].id
    "${local.spoke2_prefix}ilb"   = module.common.nsg_default["region1"].id
  }

  vnet_config = [
    {
      address_space = local.spoke2_address_space
      subnets       = local.spoke2_subnets
    }
  ]

  depends_on = [
    module.common,
  ]
}

# workload

module "spoke2_vm" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.spoke2_prefix
  name                  = "vm"
  location              = local.spoke2_location
  subnet                = module.spoke2.subnets["${local.spoke2_prefix}main"].id
  private_ip            = local.spoke2_vm_addr
  custom_data           = base64encode(local.vm_startup)
  dns_servers           = [local.hub1_dns_in_addr, ]
  storage_account       = module.common.storage_accounts["region1"]
  private_dns_zone_name = "spoke2.${local.cloud_domain}"
  tags                  = local.spoke2_tags
  depends_on = [
    module.common,
    module.hub1,
  ]
}

####################################################
# spoke3
####################################################

# base

module "spoke3" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.spoke3_prefix, "-")
  env             = "prod"
  location        = local.spoke3_location
  storage_account = module.common.storage_accounts["region1"]
  tags = {
    "env" = "prod"
  }

  create_private_dns_zone = true
  private_dns_zone_name   = "spoke3.${local.cloud_domain}"
  private_dns_zone_linked_external_vnets = {
    "hub1" = module.hub1.vnet.id
  }

  nsg_subnet_map = {
    "${local.spoke3_prefix}main"  = module.common.nsg_main["region1"].id
    "${local.spoke3_prefix}appgw" = module.common.nsg_appgw["region1"].id
    "${local.spoke3_prefix}ilb"   = module.common.nsg_default["region1"].id
  }

  vnet_config = [
    {
      address_space            = local.spoke3_address_space
      subnets                  = local.spoke3_subnets
      nat_gateway_subnet_names = ["${local.spoke3_prefix}main", ]
    }
  ]

  depends_on = [
    module.common,
  ]
}

# workload

module "spoke3_vm" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.spoke3_prefix
  name                  = "vm"
  location              = local.spoke3_location
  subnet                = module.spoke3.subnets["${local.spoke3_prefix}main"].id
  private_ip            = local.spoke3_vm_addr
  custom_data           = base64encode(local.vm_startup)
  storage_account       = module.common.storage_accounts["region1"]
  private_dns_zone_name = "spoke3.${local.cloud_domain}"
  tags                  = local.spoke3_tags
  depends_on = [
    module.common,
    module.hub1,
  ]
}
