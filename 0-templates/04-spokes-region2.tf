
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
    "${local.spoke4_prefix}main"  = module.common.nsg_main["region2"].id
    "${local.spoke4_prefix}appgw" = module.common.nsg_appgw["region2"].id
    "${local.spoke4_prefix}ilb"   = module.common.nsg_default["region2"].id
  }

  vnet_config = [
    {
      address_space = local.spoke4_address_space
      subnets       = local.spoke4_subnets
    }
  ]

  depends_on = [
    module.common,
  ]
}

# workload

module "spoke4_vm" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.spoke4_prefix
  name                  = "vm"
  location              = local.spoke4_location
  subnet                = module.spoke4.subnets["${local.spoke4_prefix}main"].id
  private_ip            = local.spoke4_vm_addr
  custom_data           = base64encode(local.vm_startup)
  dns_servers           = [local.hub2_dns_in_addr, ]
  storage_account       = module.common.storage_accounts["region2"]
  private_dns_zone_name = "spoke4.${local.cloud_domain}"
  delay_creation        = "90s"
  tags                  = local.spoke4_tags
  depends_on = [
    module.common,
    module.hub2,
  ]
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
    "${local.spoke5_prefix}main"  = module.common.nsg_main["region2"].id
    "${local.spoke5_prefix}appgw" = module.common.nsg_appgw["region2"].id
    "${local.spoke5_prefix}ilb"   = module.common.nsg_default["region2"].id
  }

  vnet_config = [
    {
      address_space = local.spoke5_address_space
      subnets       = local.spoke5_subnets
    }
  ]

  depends_on = [
    module.common,
  ]
}

# workload

module "spoke5_vm" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.spoke5_prefix
  name                  = "vm"
  location              = local.spoke5_location
  subnet                = module.spoke5.subnets["${local.spoke5_prefix}main"].id
  private_ip            = local.spoke5_vm_addr
  custom_data           = base64encode(local.vm_startup)
  dns_servers           = [local.hub2_dns_in_addr, ]
  storage_account       = module.common.storage_accounts["region2"]
  private_dns_zone_name = "spoke5.${local.cloud_domain}"
  delay_creation        = "90s"
  tags                  = local.spoke5_tags
  depends_on = [
    module.common,
    module.hub2,
  ]
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
    "${local.spoke6_prefix}main"  = module.common.nsg_main["region2"].id
    "${local.spoke6_prefix}appgw" = module.common.nsg_appgw["region2"].id
    "${local.spoke6_prefix}ilb"   = module.common.nsg_default["region2"].id
  }

  vnet_config = [
    {
      address_space            = local.spoke6_address_space
      subnets                  = local.spoke6_subnets
      nat_gateway_subnet_names = ["${local.spoke6_prefix}main", ]
    }
  ]

  depends_on = [
    module.common,
  ]
}

# workload

module "spoke6_vm" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.spoke6_prefix
  name                  = "vm"
  location              = local.spoke6_location
  subnet                = module.spoke6.subnets["${local.spoke6_prefix}main"].id
  private_ip            = local.spoke6_vm_addr
  custom_data           = base64encode(local.vm_startup)
  storage_account       = module.common.storage_accounts["region2"]
  private_dns_zone_name = "spoke6.${local.cloud_domain}"
  delay_creation        = "90s"
  tags                  = local.spoke6_tags
  depends_on = [
    module.common,
    module.hub2,
  ]
}
