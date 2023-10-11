
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
      #subnets_nat_gateway = ["${local.spoke4_prefix}main", ]
    }
  ]

  vm_config = [
    {
      name         = "vm"
      subnet       = "${local.spoke4_prefix}main"
      private_ip   = local.spoke4_vm_addr
      custom_data  = base64encode(local.vm_startup)
      dns_servers  = [local.hub2_dns_in_addr, ]
      source_image = "ubuntu-22"
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

  vm_config = [
    {
      name         = "vm"
      subnet       = "${local.spoke5_prefix}main"
      private_ip   = local.spoke5_vm_addr
      custom_data  = base64encode(local.vm_startup)
      dns_servers  = [local.hub2_dns_in_addr, ]
      source_image = "ubuntu-22"
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
      address_space = local.spoke6_address_space
      subnets       = local.spoke6_subnets
      #subnets_nat_gateway = ["${local.spoke6_prefix}main", ]
    }
  ]

  vm_config = [
    {
      name             = "vm"
      subnet           = "${local.spoke6_prefix}main"
      private_ip       = local.spoke6_vm_addr
      enable_public_ip = true
      custom_data      = base64encode(local.vm_startup)
      dns_servers      = [local.hub2_dns_in_addr, ]
      source_image     = "ubuntu-22"
    }
  ]
  depends_on = [
    module.common,
  ]
}
