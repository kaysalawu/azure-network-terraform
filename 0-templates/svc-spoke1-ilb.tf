
####################################################
# backends
####################################################

module "spoke1_be1" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.spoke1_prefix
  name                  = "be1"
  location              = local.spoke1_location
  subnet                = module.spoke1.subnets["MainSubnet"].id
  enable_public_ip      = true
  custom_data           = base64encode(local.vm_startup)
  storage_account       = module.common.storage_accounts["region1"]
  private_dns_zone_name = "spoke1.${local.cloud_domain}"
  tags                  = local.spoke1_tags
  depends_on            = [module.spoke1]
}

module "spoke1_be2" {
  source                = "../../modules/linux"
  resource_group        = azurerm_resource_group.rg.name
  prefix                = local.spoke1_prefix
  name                  = "be2"
  location              = local.spoke1_location
  subnet                = module.spoke1.subnets["MainSubnet"].id
  enable_public_ip      = true
  custom_data           = base64encode(local.vm_startup)
  storage_account       = module.common.storage_accounts["region1"]
  private_dns_zone_name = "spoke1.${local.cloud_domain}"
  tags                  = local.spoke1_tags
  depends_on            = [module.spoke1]
}

####################################################
# internal load balancer
####################################################

module "spoke1_web_ilb" {
  source                                 = "../../modules/azure-load-balancer"
  resource_group_name                    = azurerm_resource_group.rg.name
  location                               = local.spoke1_location
  prefix                                 = trimsuffix(local.spoke1_prefix, "-")
  name                                   = "web"
  type                                   = "private"
  frontend_subnet_id                     = module.spoke1.subnets["LoadBalancerSubnet"].id
  frontend_private_ip_address_allocation = "Static"
  frontend_private_ip_address            = local.spoke1_ilb_addr
  lb_sku                                 = "Standard"

  remote_port = { ssh = ["Tcp", "80"] }
  lb_port     = { http = ["80", "Tcp", "80"] }
  lb_probe    = { http = ["Tcp", "80", ""] }

  backend_address_pools = {
    name = "web"
    addresses = [
      {
        name               = module.spoke1_be1.vm.name
        virtual_network_id = module.spoke1.vnet.id
        ip_address         = module.spoke1_be1.vm.private_ip_address
      },
      {
        name               = module.spoke1_be2.vm.name
        virtual_network_id = module.spoke1.vnet.id
        ip_address         = module.spoke1_be2.vm.private_ip_address
      }
    ]
  }
}
