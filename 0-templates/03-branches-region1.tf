
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
  tags = {
    "nodeType" = "branch"
  }

  nsg_subnet_map = {
    #"${local.branch1_prefix}main" = module.common.nsg_main["region1"].id
    #"${local.branch1_prefix}int"  = module.common.nsg_main["region1"].id
    #"${local.branch1_prefix}ext"  = module.common.nsg_nva["region1"].id
  }

  vnet_config = [
    {
      address_space = local.branch1_address_space
      subnets       = local.branch1_subnets
    }
  ]

  vm_config = [
    {
      name             = "vm"
      subnet           = "${local.branch1_prefix}main"
      private_ip       = local.branch1_vm_addr
      custom_data      = base64encode(local.vm_startup)
      source_image     = "ubuntu-20"
      use_vm_extension = false
      dns_servers      = [local.branch1_dns_addr, ]
      delay_creation   = "120s"
    },
    {
      name             = "dns"
      subnet           = "${local.branch1_prefix}main"
      private_ip       = local.branch1_dns_addr
      custom_data      = base64encode(local.branch_unbound_startup)
      source_image     = "debian-10"
      use_vm_extension = true
    }
  ]
  depends_on = [
    module.common,
  ]
}
