
locals {
  onprem_bak_srv_nic = module.onprem.interface["bak-srv"].name
}

####################################################
# onprem
####################################################

# env
#----------------------------

module "onprem" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.onprem_prefix, "-")
  location        = local.onprem_location
  storage_account = azurerm_storage_account.region1

  nsg_config = {
    "${local.onprem_prefix}main" = azurerm_network_security_group.nsg_region1_main.id
    "${local.onprem_prefix}int"  = azurerm_network_security_group.nsg_region1_main.id
    "${local.onprem_prefix}ext"  = azurerm_network_security_group.nsg_region1_nva.id
  }

  vnet_config = [
    {
      address_space = local.onprem_address_space
      subnets       = local.onprem_subnets
      enable_ergw   = true
    }
  ]

  vm_config = [
    {
      name             = "bak-srv"
      subnet           = "${local.onprem_prefix}main"
      private_ip       = local.onprem_vm_addr
      custom_data      = base64encode(local.vm_startup)
      source_image     = "ubuntu"
      dns_servers      = [local.onprem_dns_addr, ]
      use_vm_extension = false
      delay_creation   = "60s"
    },
    {
      name             = "dns"
      subnet           = "${local.onprem_prefix}main"
      private_ip       = local.onprem_dns_addr
      custom_data      = base64encode(local.onprem_unbound_config)
      source_image     = "ubuntu"
      use_vm_extension = true
    }
  ]
}
