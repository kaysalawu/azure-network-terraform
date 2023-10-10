
####################################################
# branch2
####################################################

# env
#----------------------------

module "branch2" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.branch2_prefix, "-")
  location        = local.branch2_location
  storage_account = azurerm_storage_account.region1

  nsg_config = {
    "${local.branch2_prefix}main" = azurerm_network_security_group.nsg_region1_main.id
    "${local.branch2_prefix}int"  = azurerm_network_security_group.nsg_region1_main.id
    "${local.branch2_prefix}ext"  = azurerm_network_security_group.nsg_region1_nva.id
  }

  vnet_config = [
    {
      address_space = local.branch2_address_space
      subnets       = local.branch2_subnets
      enable_ergw   = true
    }
  ]

  vm_config = [
    {
      name         = "vm1"
      subnet       = "${local.branch2_prefix}main"
      private_ip   = local.branch2_vm_addr
      custom_data  = base64encode(local.vm_startup)
      source_image = "ubuntu"
      dns_servers  = [local.branch2_dns_addr, ]
    },
    {
      name             = "dns"
      subnet           = "${local.branch2_prefix}main"
      private_ip       = local.branch2_dns_addr
      custom_data      = base64encode(local.branch_unbound_config)
      source_image     = "debian"
      use_vm_extension = true
    }
  ]
}
