
/*
This template creates PrivateLink Service in spoke6 access via private endpoint in hub1.
It also creates PrivateLink Service (app service) accessed via private endpoint in hub1.
*/

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

resource "azurerm_private_dns_a_record" "hub2_spoke6_pls_pep" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = local.hub2_spoke6_pep_host
  zone_name           = module.hub2.private_dns_zone.name
  ttl                 = 300
  records = [
    azurerm_private_endpoint.hub2_spoke6_pls_pep.private_service_connection[0].private_ip_address,
  ]
}

####################################################
# private link
####################################################

locals {
  private_dns_zone_privatelink_vnet_links_hub2 = {
    "pl-blob" = azurerm_private_dns_zone.privatelink_blob.name
    "pl-apps" = azurerm_private_dns_zone.privatelink_appservice.name
  }
}

# links
#----------------------------

resource "azurerm_private_dns_zone_virtual_network_link" "hub2_privatelink_vnet_links" {
  for_each              = local.private_dns_zone_privatelink_vnet_links_hub2
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = "${local.hub2_prefix}${each.key}-vnet-link"
  private_dns_zone_name = each.value
  virtual_network_id    = module.hub2.vnet.id
  registration_enabled  = false
  timeouts {
    create = "60m"
  }
}

####################################################
# app service
####################################################

module "spoke6_apps" {
  source            = "../../modules/app-service"
  resource_group    = azurerm_resource_group.rg.name
  location          = local.spoke6_location
  prefix            = lower(local.spoke6_prefix)
  name              = random_id.random.hex
  docker_image_name = "ksalawu/web:latest"
  subnet_id         = module.spoke6.subnets["AppServiceSubnet"].id
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.hub2_privatelink_vnet_links,
  ]
}

# private endpoint

resource "azurerm_private_endpoint" "hub2_spoke6_apps_pep" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}spoke6-apps-pep"
  location            = local.hub2_location
  subnet_id           = module.hub2.subnets["PrivateEndpointSubnet"].id

  private_service_connection {
    name                           = "${local.hub2_prefix}spoke6-apps-svc-conn"
    private_connection_resource_id = module.spoke6_apps.app_service_id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = "${local.hub2_prefix}spoke6-apps-zg"
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_appservice.id]
  }
  depends_on = [
    azurerm_private_endpoint.hub2_spoke6_pls_pep,
  ]
}
