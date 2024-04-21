
locals {
  frontend_ipv4 = module.azure_lb_dual_stack.public_ip_addresses["AppV4"]
  frontend_ipv6 = module.azure_lb_dual_stack.public_ip_addresses["AppV6"]
}

###################################################
# external load balancer
###################################################

module "azure_lb_dual_stack" {
  source              = "../../modules/azure-load-balancer"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.spoke3_location
  prefix              = trimsuffix(local.spoke3_prefix, "-")
  name                = "dualStack"
  type                = "public"
  lb_sku              = "Standard"
  enable_dual_stack   = local.enable_ipv6

  log_analytics_workspace_name = module.common.log_analytics_workspaces["region1"].name

  frontend_ip_configuration = [
    {
      name              = "AppV4"
      subnet_id         = module.spoke3.subnets["LoadBalancerSubnet"].id
      domain_name_label = "${lower(replace(local.spoke3_prefix, "-", ""))}appv4"
    },
    {
      name                      = "AppV6"
      subnet_id                 = module.spoke3.subnets["LoadBalancerSubnet"].id
      public_ip_address_version = "IPv6"
      domain_name_label         = "${lower(replace(local.spoke3_prefix, "-", ""))}appv6"
    },
  ]

  probes = [
    { name         = "Http8080"
      protocol     = "Http"
      port         = "8080"
      request_path = "/healthz"
      interval     = 15

    },
  ]

  backend_pools = [
    {
      name = "AppV4"
      addresses = [
        {
          name               = "spoke3V4"
          virtual_network_id = module.spoke3.vnet.id
          ip_address         = module.spoke3_vm.private_ip_address
        },
      ]
    },
    {
      name = "AppV6"
      addresses = [
        {
          name               = "spoke3V6"
          virtual_network_id = module.spoke3.vnet.id
          ip_address         = module.spoke3_vm.private_ipv6_address
        },
      ]
    },
  ]

  lb_rules = [
    {
      name                           = "AppV4"
      protocol                       = "Tcp"
      frontend_port                  = "80"
      backend_port                   = "8080"
      frontend_ip_configuration_name = "AppV4"
      backend_address_pool_name      = ["AppV4", ]
      probe_name                     = "Http8080"
      idle_timeout_in_minutes        = 4
    },
    {
      name                           = "AppV6"
      protocol                       = "Tcp"
      frontend_port                  = "80"
      backend_port                   = "8080"
      frontend_ip_configuration_name = "AppV6"
      backend_address_pool_name      = ["AppV6", ]
      probe_name                     = "Http8080"
      idle_timeout_in_minutes        = 4
    }
  ]

  outbound_rules = [
    # {
    #   name                           = "SnatV4"
    #   frontend_ip_configuration_name = "AppV4"
    #   backend_address_pool_name      = "AppV4"
    #   protocol                       = "All"
    #   allocated_outbound_ports       = 1024
    # },
    # {
    #   name                           = "SnatV6"
    #   frontend_ip_configuration_name = "AppV6"
    #   backend_address_pool_name      = "AppV4"
    #   protocol                       = "All"
    #   allocated_outbound_ports       = 1024
    # },
  ]
}

output "azure_lb_dual_stack" {
  value = {
    frontend_ipv4      = local.frontend_ipv4
    frontend_ipv6      = local.frontend_ipv6
    frontend_ipv4_host = "ipv4-${local.frontend_ipv4}.nip.io"
    frontend_ipv6_host = replace("ipv6-${local.frontend_ipv6}.sslip.io", ":", "-")
  }
}
