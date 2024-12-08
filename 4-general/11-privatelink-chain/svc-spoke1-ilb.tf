
####################################################
# private link service
####################################################

# internal load balancer

module "spoke1_lb" {
  source              = "../../modules/azure-load-balancer"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.spoke1_location
  prefix              = trimsuffix(local.spoke1_prefix, "-")
  name                = "pls"
  type                = "private"
  lb_sku              = "Standard"

  log_analytics_workspace_name = module.common.log_analytics_workspaces["region1"].name

  frontend_ip_configuration = [
    {
      name                          = "pls"
      zones                         = ["1", "2", "3"]
      subnet_id                     = module.spoke1.subnets["LoadBalancerSubnet"].id
      private_ip_address            = local.spoke1_ilb_addr
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
          ip_configuration_name = module.spoke1_vm.interface_names["${local.spoke1_prefix}vm-main-nic"]
          network_interface_id  = module.spoke1_vm.interface_ids["${local.spoke1_prefix}vm-main-nic"]
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
  depends_on = [
    module.spoke1,
  ]
}

# service

resource "azurerm_private_link_service" "spoke1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.spoke1_prefix}pls"
  location            = local.spoke1_location
  tags                = local.spoke1_tags

  nat_ip_configuration {
    name      = "pls-nat-ip-config"
    primary   = true
    subnet_id = module.spoke1.subnets["PrivateLinkServiceSubnet"].id
  }

  load_balancer_frontend_ip_configuration_ids = [
    module.spoke1_lb.frontend_ip_configurations["pls"].id,
  ]

  lifecycle {
    ignore_changes = [
      nat_ip_configuration
    ]
  }
  depends_on = [
    module.spoke1,
  ]
}

# endpoint

resource "azurerm_private_endpoint" "hub1_spoke1_pls_pep" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}spoke1-pls-pep"
  location            = local.hub1_location
  subnet_id           = module.hub1.subnets["PrivateEndpointSubnet"].id

  private_service_connection {
    name                           = "${local.hub1_prefix}spoke1-pls-svc-conn"
    private_connection_resource_id = azurerm_private_link_service.spoke1.id
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "pep-ip-config"
    private_ip_address = local.hub1_spoke1_pls_pep_ip
  }
  depends_on = [
    module.spoke1,
    module.hub1,
  ]
}

resource "azurerm_private_dns_a_record" "hub1_spoke1_pls_pep" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = local.hub1_spoke1_pep_host
  zone_name           = module.common.private_dns_zones[local.region1_dns_zone].name
  ttl                 = 300
  records = [
    azurerm_private_endpoint.hub1_spoke1_pls_pep.private_service_connection[0].private_ip_address,
  ]
}

