
locals {
  #spoke6_vm_public_ip = module.spoke6.vm_public_ip[local.spoke6_vm_name]
}

####################################################
# spoke4
####################################################

# base

module "spoke4" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.spoke4_prefix, "-")
  location        = local.spoke4_location
  storage_account = module.common.storage_accounts["region2"]

  private_dns_zone_name = azurerm_private_dns_zone.global.name
  private_dns_prefix    = local.spoke4_dns_zone

  nsg_subnet_map = {
    "${local.spoke4_prefix}main"  = module.common.nsg_main["region2"].id
    "${local.spoke4_prefix}appgw" = module.common.nsg_appgw["region2"].id
    "${local.spoke4_prefix}ilb"   = module.common.nsg_default["region2"].id
  }

  vnet_config = [
    {
      address_space = local.spoke4_address_space
      subnets       = local.spoke4_subnets
      #subnets_nat_gateway = ["${local.spoke4_prefix}main", ]
    }
  ]

  vm_config = [
    {
      name         = "vm"
      dns_host     = local.spoke4_vm_dns_host
      subnet       = "${local.spoke4_prefix}main"
      private_ip   = local.spoke4_vm_addr
      custom_data  = base64encode(local.vm_startup)
      source_image = "ubuntu"
    }
  ]
  depends_on = [
    module.common,
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
  location        = local.spoke5_location
  storage_account = module.common.storage_accounts["region2"]

  private_dns_zone_name = azurerm_private_dns_zone.global.name
  private_dns_prefix    = local.spoke5_dns_zone

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

  vm_config = [
    {
      name         = "vm"
      dns_host     = local.spoke5_vm_dns_host
      subnet       = "${local.spoke5_prefix}main"
      private_ip   = local.spoke5_vm_addr
      custom_data  = base64encode(local.vm_startup)
      source_image = "ubuntu"
    }
  ]
  depends_on = [
    module.common,
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
  location        = local.spoke6_location
  storage_account = module.common.storage_accounts["region2"]

  private_dns_zone_name = azurerm_private_dns_zone.global.name
  private_dns_prefix    = local.spoke6_dns_zone

  nsg_subnet_map = {
    "${local.spoke6_prefix}main"  = module.common.nsg_main["region2"].id
    "${local.spoke6_prefix}appgw" = module.common.nsg_appgw["region2"].id
    "${local.spoke6_prefix}ilb"   = module.common.nsg_default["region2"].id
  }

  vnet_config = [
    {
      address_space = local.spoke6_address_space
      subnets       = local.spoke6_subnets
      #subnets_nat_gateway = ["${local.spoke6_prefix}main", ]
    }
  ]

  vm_config = [
    {
      name             = "vm"
      dns_host         = local.spoke6_vm_dns_host
      subnet           = "${local.spoke6_prefix}main"
      private_ip       = local.spoke6_vm_addr
      enable_public_ip = true
      custom_data      = base64encode(local.vm_startup)
      source_image     = "ubuntu"
    }
  ]
  depends_on = [
    module.common,
  ]
}
