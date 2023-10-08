
####################################################
# dns resolver ruleset
####################################################

# ruleset
#---------------------------

# onprem

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "hub2" {
  resource_group_name                        = azurerm_resource_group.rg.name
  name                                       = "${local.hub2_prefix}ruleset"
  location                                   = local.hub2_location
  private_dns_resolver_outbound_endpoint_ids = [module.hub2.private_dns_outbound_ep.id]
}

# rules
#---------------------------

# onprem

resource "azurerm_private_dns_resolver_forwarding_rule" "hub2_onprem" {
  name                      = "${local.hub2_prefix}onprem"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub2.id
  domain_name               = "${local.onprem_domain}."
  enabled                   = true
  target_dns_servers {
    ip_address = local.branch3_dns_addr
    port       = 53
  }
  target_dns_servers {
    ip_address = local.branch1_dns_addr
    port       = 53
  }
}

# cloud

resource "azurerm_private_dns_resolver_forwarding_rule" "hub2_cloud" {
  name                      = "${local.hub2_prefix}cloud"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub2.id
  domain_name               = "${local.cloud_domain}."
  enabled                   = true
  target_dns_servers {
    ip_address = local.hub1_dns_in_addr
    port       = 53
  }
}

# links
#---------------------------

locals {
  dns_zone_linked_rulesets_hub2_onprem = {
    "hub2-onprem" = module.hub2.vnet.id
  }
}

resource "azurerm_private_dns_resolver_virtual_network_link" "hub2_onprem" {
  for_each                  = local.dns_zone_linked_rulesets_hub2_onprem
  name                      = "${local.prefix}${each.key}-vnet-link"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub2.id
  virtual_network_id        = each.value
}

####################################################
# private link service
####################################################

# ilb
#----------------------------

# internal load balancer

module "spoke6_lb" {
  source                                 = "../../modules/azlb"
  resource_group_name                    = azurerm_resource_group.rg.name
  location                               = local.spoke6_location
  prefix                                 = trimsuffix(local.spoke6_prefix, "-")
  type                                   = "private"
  private_dns_zone                       = module.spoke6.private_dns_zone.name
  dns_host                               = local.spoke6_ilb_dns_host
  frontend_subnet_id                     = module.spoke6.subnets["${local.spoke6_prefix}ilb"].id
  frontend_private_ip_address_allocation = "Static"
  frontend_private_ip_address            = local.spoke6_ilb_addr
  lb_sku                                 = "Standard"

  remote_port = { ssh = ["Tcp", "80"] }
  lb_port     = { http = ["80", "Tcp", "80"] }
  lb_probe    = { http = ["Tcp", "80", ""] }

  backends = [
    {
      name                  = module.spoke6.vm["vm"].name
      ip_configuration_name = module.spoke6.vm_interface["vm"].ip_configuration[0].name
      network_interface_id  = module.spoke6.vm_interface["vm"].id
    }
  ]
}

# private link service
#----------------------------

module "spoke6_pls" {
  source           = "../../modules/privatelink"
  resource_group   = azurerm_resource_group.rg.name
  location         = local.spoke6_location
  prefix           = trimsuffix(local.spoke6_prefix, "-")
  private_dns_zone = module.spoke6.private_dns_zone.name
  dns_host         = local.spoke6_ilb_dns_host

  nat_ip_config = [
    {
      name            = "pls-nat-ip-config"
      primary         = true
      subnet_id       = module.spoke6.subnets["${local.spoke6_prefix}pls"].id
      lb_frontend_ids = [module.spoke6_lb.frontend_ip_configuration[0].id, ]
    }
  ]
  depends_on = [
    module.spoke6_lb,
  ]
}

####################################################
# private endpoint
####################################################

resource "azurerm_private_endpoint" "hub2_spoke6_pe" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}spoke6-pe"
  location            = local.hub2_location
  subnet_id           = module.hub2.subnets["${local.hub2_prefix}pep"].id

  private_service_connection {
    name                           = "${local.hub2_prefix}spoke6-pe-psc"
    private_connection_resource_id = module.spoke6_pls.private_link_service_id
    is_manual_connection           = false
  }
}

resource "azurerm_private_dns_a_record" "hub2_spoke6_pe" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = local.hub2_pep_dns_host
  zone_name           = module.spoke6.private_dns_zone.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.hub2_spoke6_pe.private_service_connection[0].private_ip_address, ]
}
