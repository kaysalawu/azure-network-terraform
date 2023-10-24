
resource "random_id" "services_region1" {
  byte_length = 2
}

####################################################
# dns resolver ruleset
####################################################

# ruleset
#---------------------------

# onprem

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "hub1" {
  resource_group_name                        = azurerm_resource_group.rg.name
  name                                       = "${local.hub1_prefix}ruleset"
  location                                   = local.hub1_location
  private_dns_resolver_outbound_endpoint_ids = [module.hub1.private_dns_outbound_ep.id]
}

# rules
#---------------------------

# onprem

resource "azurerm_private_dns_resolver_forwarding_rule" "hub1_onprem" {
  name                      = "${local.hub1_prefix}onprem"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub1.id
  domain_name               = "${local.onprem_domain}."
  enabled                   = true
  target_dns_servers {
    ip_address = local.branch1_dns_addr
    port       = 53
  }
  target_dns_servers {
    ip_address = local.branch3_dns_addr
    port       = 53
  }
}

# cloud

resource "azurerm_private_dns_resolver_forwarding_rule" "hub1_cloud" {
  name                      = "${local.hub1_prefix}cloud"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub1.id
  domain_name               = "${local.cloud_domain}."
  enabled                   = true
  target_dns_servers {
    ip_address = local.hub2_dns_in_addr
    port       = 53
  }
}

# links
#---------------------------

locals {
  dns_zone_linked_rulesets_hub1 = {
    "hub1-onprem" = module.hub1.vnet.id
  }
}

resource "azurerm_private_dns_resolver_virtual_network_link" "hub1_onprem" {
  for_each                  = local.dns_zone_linked_rulesets_hub1
  name                      = "${local.prefix}${each.key}-vnet-link"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub1.id
  virtual_network_id        = each.value
}

####################################################
# private link service
####################################################

# ilb
#----------------------------

# internal load balancer

module "spoke3_lb" {
  source                                 = "../../modules/azlb"
  resource_group_name                    = azurerm_resource_group.rg.name
  location                               = local.spoke3_location
  prefix                                 = trimsuffix(local.spoke3_prefix, "-")
  type                                   = "private"
  private_dns_zone                       = module.spoke3.private_dns_zone.name
  dns_host                               = local.spoke3_ilb_host
  frontend_subnet_id                     = module.spoke3.subnets["${local.spoke3_prefix}ilb"].id
  frontend_private_ip_address_allocation = "Static"
  frontend_private_ip_address            = local.spoke3_ilb_addr
  lb_sku                                 = "Standard"

  remote_port = { ssh = ["Tcp", "80"] }
  lb_port     = { http = ["80", "Tcp", "80"] }
  lb_probe    = { http = ["Tcp", "80", ""] }

  backends = [
    {
      name                  = module.spoke3_vm.vm.name
      ip_configuration_name = module.spoke3_vm.interface.ip_configuration[0].name
      network_interface_id  = module.spoke3_vm.interface.id
    }
  ]
}

# private link service
#----------------------------

module "spoke3_pls" {
  source           = "../../modules/privatelink"
  resource_group   = azurerm_resource_group.rg.name
  location         = local.spoke3_location
  prefix           = trimsuffix(local.spoke3_prefix, "-")
  private_dns_zone = module.spoke3.private_dns_zone.name
  dns_host         = local.spoke3_ilb_host

  nat_ip_config = [
    {
      name            = "pls-nat-ip-config"
      primary         = true
      subnet_id       = module.spoke3.subnets["${local.spoke3_prefix}pls"].id
      lb_frontend_ids = [module.spoke3_lb.frontend_ip_configuration[0].id, ]
    }
  ]
  depends_on = [
    module.spoke3_lb,
  ]
}

# private endpoint
#----------------------------

resource "azurerm_private_endpoint" "hub1_spoke3_pls_pep" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}spoke3-pls-pep"
  location            = local.hub1_location
  subnet_id           = module.hub1.subnets["${local.hub1_prefix}pep"].id

  private_service_connection {
    name                           = "${local.hub1_prefix}spoke3-pls-svc-conn"
    private_connection_resource_id = module.spoke3_pls.private_link_service_id
    is_manual_connection           = false
  }
}

resource "azurerm_private_dns_a_record" "hub1_spoke3_pls_pep" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = local.hub1_spoke3_pep_host
  zone_name           = module.hub1.private_dns_zone.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.hub1_spoke3_pls_pep.private_service_connection[0].private_ip_address, ]
}

####################################################
# private link
####################################################

locals {
  private_dns_zone_privatelink_vnet_links_hub1 = {
    "pl-blob" = azurerm_private_dns_zone.privatelink_blob.name
    "pl-apps" = azurerm_private_dns_zone.privatelink_appservice.name
  }
}

# links
#----------------------------

resource "azurerm_private_dns_zone_virtual_network_link" "hub1_privatelink_vnet_links" {
  for_each              = local.private_dns_zone_privatelink_vnet_links_hub1
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = "${local.hub1_prefix}${each.key}-vnet-link"
  private_dns_zone_name = each.value
  virtual_network_id    = module.hub1.vnet.id
  registration_enabled  = false
  timeouts {
    create = "60m"
  }
}

# app service
#----------------------------

module "spoke3_apps" {
  source            = "../../modules/app-service"
  resource_group    = azurerm_resource_group.rg.name
  location          = local.spoke3_location
  prefix            = lower(local.spoke3_prefix)
  name              = random_id.services_region1.hex
  docker_image_name = "ksalawu/web:latest"
  subnet_id         = module.spoke3.subnets["${local.spoke3_prefix}apps"].id
  depends_on        = [azurerm_private_dns_zone_virtual_network_link.hub1_privatelink_vnet_links]
}

# private endpoint

resource "azurerm_private_endpoint" "hub1_spoke3_apps_pep" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}spoke3-apps-pep"
  location            = local.hub1_location
  subnet_id           = module.hub1.subnets["${local.hub1_prefix}pep"].id

  private_service_connection {
    name                           = "${local.hub1_prefix}spoke3-apps-svc-conn"
    private_connection_resource_id = module.spoke3_apps.app_service_id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = "${local.hub1_prefix}spoke3-apps-zg"
    private_dns_zone_ids = [azurerm_private_dns_zone.privatelink_appservice.id]
  }
}
