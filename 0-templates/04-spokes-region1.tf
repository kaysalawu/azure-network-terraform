
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

  vm_config = [
    {
      name         = "vm"
      subnet       = "${local.spoke1_prefix}main"
      private_ip   = local.spoke1_vm_addr
      custom_data  = base64encode(local.vm_startup)
      dns_servers  = [local.hub1_dns_in_addr, ]
      source_image = "ubuntu-20"
    }
  ]
  depends_on = [
    module.common,
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

  vm_config = [
    {
      name         = "vm"
      subnet       = "${local.spoke2_prefix}main"
      private_ip   = local.spoke2_vm_addr
      custom_data  = base64encode(local.vm_startup)
      dns_servers  = [local.hub1_dns_in_addr, ]
      source_image = "ubuntu-20"
    }
  ]
  depends_on = [
    module.common,
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

  vm_config = [
    {
      name             = "vm"
      subnet           = "${local.spoke3_prefix}main"
      private_ip       = local.spoke3_vm_addr
      enable_public_ip = true
      custom_data      = base64encode(local.vm_startup)
      dns_servers      = [local.hub1_dns_in_addr, ]
      source_image     = "ubuntu-20"
    }
  ]
  depends_on = [
    module.common,
  ]
}
