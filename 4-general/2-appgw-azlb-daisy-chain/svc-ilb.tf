
###################################################
# external load balancer
###################################################

module "spoke1_ilb" {
  source              = "../../modules/azure-load-balancer"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.spoke1_location
  prefix              = trimsuffix(local.spoke1_prefix, "-")
  name                = "app1"
  type                = "private"
  lb_sku              = "Standard"

  frontend_ip_configuration = [
    {
      name                          = "app"
      zones                         = ["1", "2", "3"]
      subnet_id                     = module.spoke1.subnets["LoadBalancerSubnet"].id
      private_ip_address            = local.spoke1_ilb_addr
      private_ip_address_allocation = "Static"
    },
  ]

  probes = [
    { name = "app1-https-8080", protocol = "Https", port = "8080", request_path = "/healthz" },
    { name = "app2-http-8081", protocol = "Http", port = "8081", request_path = "/healthz" },
  ]

  backend_pools = [
    {
      name = "app1"
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
      name = "app2"
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
      name                           = "app1-8080"
      protocol                       = "Tcp"
      frontend_port                  = "8080"
      backend_port                   = "8080"
      frontend_ip_configuration_name = "app"
      backend_address_pool_name      = ["app1", ]
      probe_name                     = "app1-https-8080"
    },
    {
      name                           = "app2-8081"
      protocol                       = "Tcp"
      frontend_port                  = "8081"
      backend_port                   = "8081"
      frontend_ip_configuration_name = "app"
      backend_address_pool_name      = ["app2", ]
      probe_name                     = "app2-http-8081"
    },
  ]
}
