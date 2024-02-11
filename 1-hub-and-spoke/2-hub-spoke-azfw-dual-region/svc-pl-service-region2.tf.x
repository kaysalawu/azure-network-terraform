
# This template creates PrivateLink Service (app service) accessed via private endpoint in hub2.

####################################################
# private link service
####################################################

# ilb
#----------------------------

# internal load balancer

module "spoke6_lb" {
  source              = "../../modules/azure-load-balancer"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.spoke6_location
  prefix              = trimsuffix(local.spoke6_prefix, "-")
  name                = "pls"
  type                = "private"
  lb_sku              = "Standard"

  frontend_ip_configuration = [
    {
      name                          = "pls"
      zones                         = ["1", "2", "3"]
      subnet_id                     = module.spoke6.subnets["LoadBalancerSubnet"].id
      private_ip_address            = local.spoke6_ilb_addr
      private_ip_address_allocation = "Static"
    }
  ]

  probes = [
    { name = "http", protocol = "Tcp", port = "80", request_path = "" },
  ]

  backend_pools = [
    {
      name = "pls"
      interfaces = [
        {
          ip_configuration_name = module.spoke6_vm.interface_names["${local.spoke6_prefix}vm-main-nic"]
          network_interface_id  = module.spoke6_vm.interface_ids["${local.spoke6_prefix}vm-main-nic"]
        },
      ]
    },
  ]

  lb_rules = [
    {
      name                           = "pls-80"
      protocol                       = "Tcp"
      frontend_port                  = "80"
      backend_port                   = "80"
      frontend_ip_configuration_name = "pls"
      backend_address_pool_name      = ["pls", ]
      probe_name                     = "http"
    },
  ]
}

# service
#----------------------------

module "spoke6_pls" {
  source           = "../../modules/privatelink"
  resource_group   = azurerm_resource_group.rg.name
  location         = local.spoke6_location
  prefix           = trimsuffix(local.spoke6_prefix, "-")
  private_dns_zone = module.spoke6.private_dns_zone.name
  dns_host         = local.spoke6_ilb_hostname

  nat_ip_config = [
    {
      name            = "pls-nat-ip-config"
      primary         = true
      subnet_id       = module.spoke6.subnets["PrivateLinkServiceSubnet"].id
      lb_frontend_ids = [module.spoke6_lb.frontend_ip_configurations["pls"].id, ]
    }
  ]
}

# endpoint
#----------------------------

resource "azurerm_private_endpoint" "hub2_spoke6_pls_pep" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}spoke6-pls-pep"
  location            = local.hub2_location
  subnet_id           = module.hub2.subnets["PrivateEndpointSubnet"].id

  private_service_connection {
    name                           = "${local.hub2_prefix}spoke6-pls-svc-conn"
    private_connection_resource_id = module.spoke6_pls.private_link_service_id
    is_manual_connection           = false
  }
}

# resource "azurerm_private_dns_a_record" "hub2_spoke6_pls_pep" {
#   resource_group_name = azurerm_resource_group.rg.name
#   name                = local.hub2_spoke6_pep_host
#   zone_name           = module.common.private_dns_zones["us.az.corp"].name
#   ttl                 = 300
#   records = [
#     azurerm_private_endpoint.hub2_spoke6_pls_pep.private_service_connection[0].private_ip_address,
#   ]
# }
