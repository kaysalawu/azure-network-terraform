
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
  storage_account = azurerm_storage_account.region2

  nsg_subnets = {
    "main" = azurerm_network_security_group.nsg_region2_main.id
    "int"  = azurerm_network_security_group.nsg_region2_main.id
    "ext"  = azurerm_network_security_group.nsg_region2_nva.id
  }

  vnet_config = [
    {
      address_space = local.branch3_address_space
      subnets       = local.branch3_subnets
      dns_servers   = [local.branch3_dns_addr, ]
      enable_vpngw  = false
      enable_ergw   = false
    }
  ]

  vm_config = [
    {
      name        = "vm1"
      custom_data = base64encode(local.vm_startup)
      private_ip  = local.branch3_vm_addr
      #use_vm_extension = true
    },
  ]

  dns_config = [
    {
      name             = "dns"
      private_ip       = local.branch3_dns_addr
      custom_data      = base64encode(local.branch_unbound_config)
      use_vm_extension = true
    }
  ]
}
