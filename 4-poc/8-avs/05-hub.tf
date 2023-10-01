

locals {
  #hub_vpngw_bgp0  = module.hub.vpngw.bgp_settings[0].peering_addresses[0].default_addresses[0]
  #hub_vpngw_bgp1  = module.hub.vpngw.bgp_settings[0].peering_addresses[1].default_addresses[0]
  hub_ars_bgp0    = tolist(module.hub.ars.virtual_router_ips)[0]
  hub_ars_bgp1    = tolist(module.hub.ars.virtual_router_ips)[1]
  hub_ars_bgp_asn = module.hub.ars.virtual_router_asn
  hub_dns_in_ip   = module.hub.private_dns_inbound_ep.ip_configurations[0].private_ip_address
}

####################################################
# base
####################################################

module "hub" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.hub_prefix, "-")
  location        = local.hub_location
  storage_account = azurerm_storage_account.region1

  private_dns_zone = local.hub_dns_zone
  dns_zone_linked_vnets = {
    "core1"  = { vnet = module.core1.vnet.id, registration_enabled = false }
    "core2"  = { vnet = module.core2.vnet.id, registration_enabled = false }
    "yellow" = { vnet = module.yellow.vnet.id, registration_enabled = false }
  }
  dns_zone_linked_rulesets = {
    "hub" = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub_onprem.id
  }

  nsg_config = {
    "${local.hub_prefix}main" = azurerm_network_security_group.nsg_region1_main.id
    "${local.hub_prefix}nva"  = azurerm_network_security_group.nsg_region1_nva.id
    "${local.hub_prefix}ilb"  = azurerm_network_security_group.nsg_region1_default.id
  }

  vnet_config = [
    {
      address_space               = local.hub_address_space
      subnets                     = local.hub_subnets
      enable_private_dns_resolver = true
      enable_ergw                 = true
      enable_vpngw                = false
      enable_ars                  = true
      enable_firewall             = false

      vpngw_config = [
        {
          sku = "VpnGw2AZ"
          asn = local.hub_vpngw_asn
        }
      ]
    }
  ]

  vm_config = [
    {
      name         = local.hub_vm_dns_host
      subnet       = "${local.hub_prefix}main"
      private_ip   = local.hub_vm_addr
      custom_data  = base64encode(local.vm_startup)
      source_image = "ubuntu"
    }
  ]
}

####################################################
# internal lb
####################################################

resource "azurerm_lb" "hub_nva_lb" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub_prefix}nva-lb"
  location            = local.hub_location
  sku                 = "Standard"
  frontend_ip_configuration {
    name                          = "${local.hub_prefix}nva-lb-feip"
    subnet_id                     = module.hub.subnets["${local.hub_prefix}ilb"].id
    private_ip_address            = local.hub_nva_ilb_addr
    private_ip_address_allocation = "Static"
  }
  lifecycle {
    ignore_changes = [frontend_ip_configuration, ]
  }
}

# backend

resource "azurerm_lb_backend_address_pool" "hub_nva" {
  name            = "${local.hub_prefix}nva-beap"
  loadbalancer_id = azurerm_lb.hub_nva_lb.id
}

resource "azurerm_lb_backend_address_pool_address" "hub_nva" {
  name                    = "${local.hub_prefix}nva-beap-addr"
  backend_address_pool_id = azurerm_lb_backend_address_pool.hub_nva.id
  virtual_network_id      = module.hub.vnet.id
  ip_address              = local.hub_nva_addr
}

# probe

resource "azurerm_lb_probe" "hub_nva_lb_probe" {
  name                = "${local.hub_prefix}nva-probe"
  interval_in_seconds = 5
  number_of_probes    = 2
  loadbalancer_id     = azurerm_lb.hub_nva_lb.id
  port                = 22
  protocol            = "Tcp"
}

# rule

resource "azurerm_lb_rule" "hub_nva" {
  name     = "${local.hub_prefix}nva-rule"
  protocol = "All"
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.hub_nva.id
  ]
  loadbalancer_id                = azurerm_lb.hub_nva_lb.id
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "${local.hub_prefix}nva-lb-feip"
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 30
  load_distribution              = "Default"
  probe_id                       = azurerm_lb_probe.hub_nva_lb_probe.id
}

####################################################
# dns resolver ruleset
####################################################

# onprem

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "hub_onprem" {
  resource_group_name                        = azurerm_resource_group.rg.name
  name                                       = "${local.hub_prefix}onprem"
  location                                   = local.hub_location
  private_dns_resolver_outbound_endpoint_ids = [module.hub.private_dns_outbound_ep.id]
}

resource "azurerm_private_dns_resolver_forwarding_rule" "hub_onprem" {
  name                      = "${local.hub_prefix}onprem"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.hub_onprem.id
  domain_name               = "${local.onprem_domain}."
  enabled                   = true
  target_dns_servers {
    ip_address = local.avs_dns_addr
    port       = 53
  }
}
