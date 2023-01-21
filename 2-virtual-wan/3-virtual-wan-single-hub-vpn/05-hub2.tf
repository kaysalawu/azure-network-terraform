
locals {
  hub2_vpngw_bgp0 = module.hub2.vpngw.bgp_settings[0].peering_addresses[0].default_addresses[0]
  hub2_vpngw_bgp1 = module.hub2.vpngw.bgp_settings[0].peering_addresses[1].default_addresses[0]
}

# env
#----------------------------

module "hub2" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.hub2_prefix, "-")
  location        = local.hub2_location
  storage_account = azurerm_storage_account.region2

  private_dns_zone = local.hub2_dns_zone
  dns_zone_linked_vnets = {
    "spoke4" = module.spoke4.vnet.id
    "spoke5" = module.spoke5.vnet.id
    "spoke6" = module.spoke6.vnet.id
  }
  dns_zone_linked_rulesets = {
    "hub2" = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub2_onprem.id
  }

  nsg_subnets = {
    "main" = azurerm_network_security_group.nsg_region2_main.id
    "nva"  = azurerm_network_security_group.nsg_region2_nva.id
    #"ilb"  = azurerm_network_security_group.nsg_region2_default.id
    #"dns"  = azurerm_network_security_group.nsg_region2_default.id
  }

  vnet_config = [
    {
      address_space               = local.hub2_address_space
      subnets                     = local.hub2_subnets
      enable_private_dns_resolver = true
      enable_ergw                 = false
      enable_vpngw                = true
      enable_ars                  = false

      vpngw_config = [
        {
          asn = local.hub2_vpngw_asn
        }
      ]
    }
  ]

  vm_config = [
    {
      name        = local.hub2_vm_dns_host
      private_ip  = local.hub2_vm_addr
      custom_data = base64encode(local.vm_startup)
    }
  ]
}

# udr
#----------------------------

# route table

resource "azurerm_route_table" "hub2_vpngw_rt" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}vpngw-rt"
  location            = local.region2

  disable_bgp_route_propagation = false
}

# routes

locals {
  hub2_vpngw_routes = {
    spoke5 = local.spoke5_address_space[0],
  }
}

resource "azurerm_route" "hub2_vpngw_rt_routes" {
  for_each               = local.hub2_vpngw_routes
  resource_group_name    = azurerm_resource_group.rg.name
  name                   = "${local.hub2_prefix}vpngw-rt-${each.key}-route"
  route_table_name       = azurerm_route_table.hub2_vpngw_rt.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_nva_ilb_addr
}

# association

resource "azurerm_subnet_route_table_association" "hub2_vpngw_rt_spoke_route" {
  subnet_id      = module.hub2.subnets["GatewaySubnet"].id
  route_table_id = azurerm_route_table.hub2_vpngw_rt.id
}

# internal lb
#----------------------------

resource "azurerm_lb" "hub2_nva_lb" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}nva-lb"
  location            = local.hub2_location
  sku                 = "Standard"
  frontend_ip_configuration {
    name                          = "${local.hub2_prefix}nva-lb-feip"
    subnet_id                     = module.hub2.subnets["${local.hub2_prefix}ilb"].id
    private_ip_address            = local.hub2_nva_ilb_addr
    private_ip_address_allocation = "Static"
  }

  lifecycle {
    ignore_changes = [frontend_ip_configuration, ]
  }
}

# backend

resource "azurerm_lb_backend_address_pool" "hub2_nva" {
  name            = "${local.hub2_prefix}nva-beap"
  loadbalancer_id = azurerm_lb.hub2_nva_lb.id
}

resource "azurerm_lb_backend_address_pool_address" "hub2_nva" {
  name                    = "${local.hub2_prefix}nva-beap-addr"
  backend_address_pool_id = azurerm_lb_backend_address_pool.hub2_nva.id
  virtual_network_id      = module.hub2.vnet.id
  ip_address              = local.hub2_nva_addr
}

# probe

resource "azurerm_lb_probe" "hub2_nva1_lb_probe" {
  name                = "${local.hub2_prefix}nva-probe"
  interval_in_seconds = 5
  number_of_probes    = 2
  loadbalancer_id     = azurerm_lb.hub2_nva_lb.id
  port                = 22
  protocol            = "Tcp"
}

# rule

resource "azurerm_lb_rule" "hub2_nva" {
  name     = "${local.hub2_prefix}nva-rule"
  protocol = "All"
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.hub2_nva.id
  ]
  loadbalancer_id                = azurerm_lb.hub2_nva_lb.id
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "${local.hub2_prefix}nva-lb-feip"
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 30
  load_distribution              = "Default"
  probe_id                       = azurerm_lb_probe.hub2_nva1_lb_probe.id
}

# dns resolver ruleset
#----------------------------

# onprem

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "hub2_onprem" {
  resource_group_name                        = azurerm_resource_group.rg.name
  name                                       = "${local.hub2_prefix}onprem"
  location                                   = local.hub2_location
  private_dns_resolver_outbound_endpoint_ids = [module.hub2.private_dns_outbound_ep.id]
}

resource "azurerm_private_dns_resolver_forwarding_rule" "hub2_onprem" {
  name                      = "${local.hub2_prefix}onprem"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub2_onprem.id
  domain_name               = "${local.onprem_domain}."
  enabled                   = true
  target_dns_servers {
    ip_address = local.branch3_dns_addr
    port       = 53
  }
}

# private endpoint
#----------------------------

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
  name                = local.hub1_pep_dns_host
  zone_name           = local.hub2_dns_zone
  ttl                 = 300
  records             = [azurerm_private_endpoint.hub2_spoke6_pe.private_service_connection[0].private_ip_address, ]
}
