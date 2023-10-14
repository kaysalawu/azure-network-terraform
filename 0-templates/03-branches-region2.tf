
####################################################
# branch3
####################################################

# env
#----------------------------

module "branch3" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.branch3_prefix, "-")
  location        = local.branch3_location
  storage_account = module.common.storage_accounts["region2"]
  tags            = local.branch1_tags

  nsg_subnet_map = {
    #"${local.branch3_prefix}main" = module.common.nsg_main["region2"].id
    #"${local.branch3_prefix}int"  = module.common.nsg_main["region2"].id
    #"${local.branch3_prefix}ext"  = module.common.nsg_nva["region2"].id
  }

  vnet_config = [
    {
      address_space = local.branch3_address_space
      subnets       = local.branch3_subnets
      #nat_gateway_subnet_names = ["${local.branch3_prefix}main", ]
    }
  ]

  depends_on = [
    module.common,
  ]
}

# dns
#----------------------------

module "branch3_dns" {
  source           = "../../modules/linux"
  resource_group   = azurerm_resource_group.rg.name
  prefix           = local.branch3_prefix
  name             = "dns"
  location         = local.branch3_location
  subnet           = module.branch3.subnets["${local.branch3_prefix}main"].id
  private_ip       = local.branch3_dns_addr
  enable_public_ip = true
  source_image     = "ubuntu-20"
  custom_data      = base64encode(local.branch_unbound_startup)
  storage_account  = module.common.storage_accounts["region2"]
  tags             = local.branch3_tags
  depends_on = [
    module.branch3,
  ]
}

# workload
#----------------------------

module "branch3_web" {
  source           = "../../modules/linux"
  resource_group   = azurerm_resource_group.rg.name
  prefix           = local.branch3_prefix
  name             = "vm"
  location         = local.branch3_location
  subnet           = module.branch3.subnets["${local.branch3_prefix}main"].id
  private_ip       = local.branch3_vm_addr
  enable_public_ip = true
  source_image     = "ubuntu-20"
  custom_data      = base64encode(local.vm_startup)
  dns_servers      = [local.branch3_dns_addr, ]
  storage_account  = module.common.storage_accounts["region2"]
  tags             = local.branch3_tags
  depends_on = [
    module.branch3_dns,
    module.branch3_nva,
  ]
}
