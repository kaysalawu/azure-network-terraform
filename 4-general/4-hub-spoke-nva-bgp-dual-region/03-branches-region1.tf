
####################################################
# branch1
####################################################

# env
#----------------------------

module "branch1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.branch1_prefix, "-")
  location        = local.branch1_location
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.branch1_tags

  nsg_subnet_map = {
    #"${local.branch1_prefix}main" = module.common.nsg_main["region1"].id
    #"${local.branch1_prefix}int"  = module.common.nsg_main["region1"].id
    #"${local.branch1_prefix}ext"  = module.common.nsg_nva["region1"].id
  }

  vnet_config = [
    {
      address_space = local.branch1_address_space
      subnets       = local.branch1_subnets
      #nat_gateway_subnet_names = ["${local.branch1_prefix}main", ]
    }
  ]

  depends_on = [
    module.common,
  ]
}

# dns
#----------------------------

module "branch1_dns" {
  source           = "../../modules/linux"
  resource_group   = azurerm_resource_group.rg.name
  prefix           = local.branch1_prefix
  name             = "dns"
  location         = local.branch1_location
  subnet           = module.branch1.subnets["${local.branch1_prefix}main"].id
  private_ip       = local.branch1_dns_addr
  enable_public_ip = true
  source_image     = "ubuntu-20"
  custom_data      = base64encode(local.branch_unbound_startup)
  storage_account  = module.common.storage_accounts["region1"]
  tags             = local.branch1_tags
  depends_on = [
    module.branch1,
  ]
}

# workload
#----------------------------

module "branch1_vm" {
  source           = "../../modules/linux"
  resource_group   = azurerm_resource_group.rg.name
  prefix           = local.branch1_prefix
  name             = "vm"
  location         = local.branch1_location
  subnet           = module.branch1.subnets["${local.branch1_prefix}main"].id
  private_ip       = local.branch1_vm_addr
  enable_public_ip = true
  source_image     = "ubuntu-20"
  custom_data      = base64encode(local.vm_startup)
  dns_servers      = [local.branch1_dns_addr, ]
  storage_account  = module.common.storage_accounts["region1"]
  tags             = local.branch1_tags
  depends_on = [
    module.branch1_dns,
    module.branch1_nva,
  ]
}
