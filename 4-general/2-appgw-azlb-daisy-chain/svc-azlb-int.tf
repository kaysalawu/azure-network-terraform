
####################################################
# internal load balancer
####################################################

module "spoke1_wdp_ilb" {
  source                                 = "../../modules/azlb"
  resource_group_name                    = azurerm_resource_group.rg.name
  location                               = local.spoke1_location
  prefix                                 = trimsuffix(local.spoke1_prefix, "-")
  name                                   = "wdp"
  type                                   = "private"
  frontend_subnet_id                     = module.spoke1.subnets["LoadBalancerSubnet"].id
  frontend_private_ip_address_allocation = "Static"
  frontend_private_ip_address            = local.spoke1_ilb_addr
  lb_sku                                 = "Standard"

  remote_port = { ssh = ["Tcp", "80"] }
  lb_port     = { http = ["80", "Tcp", "80"] }
  lb_probe    = { http = ["Tcp", "80", ""] }

  backend_address_pools = {
    name = "wdp"
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
    # interfaces = [
    #   {
    #     name                  = "be1"
    #     ip_configuration_name = module.spoke1_be1.interface.ip_configuration[0].name
    #     network_interface_id  = module.spoke1_be1.interface.id
    #   },
    #   {
    #     name                  = "be2"
    #     ip_configuration_name = module.spoke1_be2.interface.ip_configuration[0].name
    #     network_interface_id  = module.spoke1_be2.interface.id
    #   }
    # ]
  }
}
