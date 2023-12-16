
###################################################
# external load balancer
###################################################

module "spoke1_ilb" {
  source              = "../../modules/azure-load-balancer"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.spoke1_location
  prefix              = trimsuffix(local.spoke1_prefix, "-")
  name                = "wdp"
  type                = "private"
  lb_sku              = "Standard"

  frontend_ip_configuration = [
    {
      name                          = "wdp"
      zones                         = ["1", "2", "3"]
      subnet_id                     = module.spoke1.subnets["LoadBalancerSubnet"].id
      private_ip_address            = local.spoke1_ilb_addr
      private_ip_address_allocation = "Static"
    },
    # {
    #   name      = "pace"
    #   zones     = ["1", "2", "3"]
    #   subnet_id = module.spoke1.subnets["LoadBalancerSubnet"].id
    # }
  ]

  probes = [
    { name = "ssh", protocol = "Tcp", port = "22", request_path = "" },
    { name = "http", protocol = "Tcp", port = "80", request_path = "" },
    { name = "https", protocol = "Tcp", port = "443", request_path = "" },
  ]

  backend_pools = [
    {
      name = "wdp"
      addresses = [
        {
          name               = "be1"
          virtual_network_id = module.spoke1.vnet.id
          ip_address         = module.spoke1_be1.private_ip_address
        },
        {
          name               = "be2"
          virtual_network_id = module.spoke1.vnet.id
          ip_address         = module.spoke1_be2.private_ip_address
        }
      ]
    },
    {
      name = "pace"
      interfaces = [
        {
          ip_configuration_name = module.spoke1_be1.interface.ip_configuration[0].name
          network_interface_id  = module.spoke1_be1.interface.id
        },
        {
          ip_configuration_name = module.spoke1_be2.interface.ip_configuration[0].name
          network_interface_id  = module.spoke1_be2.interface.id
        }
      ]
    }
  ]

  lb_rules = [
    {
      name                           = "wdp-8080"
      protocol                       = "Tcp"
      frontend_port                  = "8080"
      backend_port                   = "8080"
      frontend_ip_configuration_name = "wdp"
      backend_address_pool_name      = ["wdp", ]
      probe_name                     = "ssh"
    },
    {
      name                           = "wdp-8081"
      protocol                       = "Tcp"
      frontend_port                  = "8081"
      backend_port                   = "8081"
      frontend_ip_configuration_name = "wdp"
      backend_address_pool_name      = ["wdp", ]
      probe_name                     = "ssh"
    },
    # {
    #   name                           = "pace-8080"
    #   protocol                       = "Tcp"
    #   frontend_port                  = "8080"
    #   backend_port                   = "8080"
    #   frontend_ip_configuration_name = "pace"
    #   backend_address_pool_name      = ["pace", ]
    #   probe_name                     = "ssh"
    # },
    # {
    #   name                           = "pace-8081"
    #   protocol                       = "Tcp"
    #   frontend_port                  = "8081"
    #   backend_port                   = "8081"
    #   frontend_ip_configuration_name = "pace"
    #   backend_address_pool_name      = ["pace", ]
    #   probe_name                     = "ssh"
    # },
  ]
}
