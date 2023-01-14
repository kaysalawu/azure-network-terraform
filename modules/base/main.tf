
locals {
  prefix = var.prefix == "" ? "" : join("-", [var.prefix, ""])
}

# vnet
#----------------------------

resource "azurerm_virtual_network" "this" {
  resource_group_name = var.resource_group
  name                = "${local.prefix}vnet"
  address_space       = var.vnet_config[0].address_space
  location            = var.location
}

# nsg
#----------------------------

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                  = var.nsg_subnets
  subnet_id                 = [for k, v in azurerm_subnet.this : v.id if length(regexall("${each.key}", k)) > 0][0]
  network_security_group_id = each.value
}

# dns
#----------------------------

resource "azurerm_private_dns_zone" "this" {
  count               = var.private_dns_zone == null ? 0 : 1
  resource_group_name = var.resource_group
  name                = var.private_dns_zone
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  count                 = var.private_dns_zone == null ? 0 : 1
  resource_group_name   = var.resource_group
  name                  = "${local.prefix}vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.this[0].name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = true
}

resource "azurerm_private_dns_zone_virtual_network_link" "external" {
  for_each              = { for k, v in var.dns_zone_linked_vnets : k => v if var.private_dns_zone != null }
  resource_group_name   = var.resource_group
  name                  = "${local.prefix}${each.key}-vnet-link"
  private_dns_zone_name = azurerm_private_dns_zone.this[0].name
  virtual_network_id    = each.value
  registration_enabled  = false
}

resource "azurerm_private_dns_resolver_virtual_network_link" "external" {
  for_each                  = { for k, v in var.dns_zone_linked_rulesets : k => v if var.private_dns_zone != null }
  name                      = "${local.prefix}${each.key}-vnet-link"
  dns_forwarding_ruleset_id = each.value
  virtual_network_id        = azurerm_virtual_network.this.id
}

# subnets
#----------------------------

resource "azurerm_subnet" "this" {
  for_each             = var.vnet_config[0].subnets
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.this.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes

  dynamic "delegation" {
    iterator = delegation
    for_each = contains(try(each.value.delegate, []), "dns") ? [1] : []
    content {
      name = "Microsoft.Network.dnsResolvers"
      service_delegation {
        actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        name    = "Microsoft.Network/dnsResolvers"
      }
    }
  }

  private_endpoint_network_policies_enabled     = length(regexall("pls", each.key)) > 0 ? false : true
  private_link_service_network_policies_enabled = length(regexall("pls", each.key)) > 0 ? false : true
}

# dns
#----------------------------

module "dns" {
  count            = length(var.dns_config) == 0 ? 0 : 1
  source           = "../../modules/debian"
  resource_group   = var.resource_group
  prefix           = var.prefix
  name             = var.dns_config[0].name
  location         = var.location
  subnet           = [for k, v in azurerm_subnet.this : v.id if length(regexall("main", k)) > 0][0]
  private_ip       = var.dns_config[0].private_ip
  use_vm_extension = var.dns_config[0].use_vm_extension
  custom_data      = var.dns_config[0].custom_data
  enable_public_ip = var.dns_config[0].public_ip == null ? false : true
  storage_account  = var.storage_account
  admin_username   = var.admin_username
  admin_password   = var.admin_password
}

# vm
#----------------------------

module "vm" {
  for_each         = { for x in var.vm_config : x.name => x }
  source           = "../../modules/ubuntu"
  resource_group   = var.resource_group
  prefix           = var.prefix
  name             = each.key
  location         = var.location
  subnet           = [for k, v in azurerm_subnet.this : v.id if length(regexall("main", k)) > 0][0]
  private_ip       = each.value.private_ip
  use_vm_extension = each.value.use_vm_extension
  custom_data      = each.value.custom_data
  enable_public_ip = each.value.public_ip == null ? false : true
  dns_servers      = var.vnet_config[0].dns_servers
  storage_account  = var.storage_account
  admin_username   = var.admin_username
  admin_password   = var.admin_password
  private_dns_zone = try(azurerm_private_dns_zone.this[0].name, "")
}

# nat
#----------------------------

resource "azurerm_public_ip" "nat" {
  count               = length(var.vnet_config[0].subnets_nat_gateway) == 0 ? 0 : 1
  resource_group_name = var.resource_group
  name                = "${local.prefix}natgw"
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat" {
  count               = length(var.vnet_config[0].subnets_nat_gateway) == 0 ? 0 : 1
  resource_group_name = var.resource_group
  name                = "${local.prefix}natgw"
  location            = var.location
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat" {
  count                = length(var.vnet_config[0].subnets_nat_gateway) == 0 ? 0 : 1
  nat_gateway_id       = azurerm_nat_gateway.nat[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
}

resource "azurerm_subnet_nat_gateway_association" "nat" {
  for_each       = toset(var.vnet_config[0].subnets_nat_gateway)
  subnet_id      = azurerm_subnet.this[each.key].id
  nat_gateway_id = azurerm_nat_gateway.nat[0].id
}


# resolver
#----------------------------

resource "azurerm_private_dns_resolver" "this" {
  count               = var.vnet_config[0].enable_private_dns_resolver ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}dns-resolver"
  location            = var.location
  virtual_network_id  = azurerm_virtual_network.this.id
}

# endpoints
#----------------------------

resource "azurerm_private_dns_resolver_inbound_endpoint" "this" {
  count                   = var.vnet_config[0].enable_private_dns_resolver ? 1 : 0
  name                    = "${local.prefix}dns-in"
  private_dns_resolver_id = azurerm_private_dns_resolver.this[0].id
  location                = var.location
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = [for k, v in azurerm_subnet.this : v.id if length(regexall("dns-in", k)) > 0][0]
  }
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "this" {
  count                   = var.vnet_config[0].enable_private_dns_resolver ? 1 : 0
  name                    = "${local.prefix}dns-out"
  private_dns_resolver_id = azurerm_private_dns_resolver.this[0].id
  location                = var.location
  subnet_id               = [for k, v in azurerm_subnet.this : v.id if length(regexall("dns-out", k)) > 0][0]
}

# route server
#----------------------------

resource "azurerm_public_ip" "ars_pip" {
  count               = var.vnet_config[0].enable_ars ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}ars-pip"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_route_server" "ars" {
  count                            = var.vnet_config[0].enable_ars ? 1 : 0
  resource_group_name              = var.resource_group
  name                             = "${local.prefix}ars"
  location                         = var.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.ars_pip[0].id
  subnet_id                        = azurerm_subnet.this["RouteServerSubnet"].id
  branch_to_branch_traffic_enabled = true

  lifecycle {
    ignore_changes = [
      subnet_id
    ]
  }
}

# vpngw
#----------------------------

resource "azurerm_public_ip" "vpngw_pip0" {
  count               = var.vnet_config[0].enable_vpngw ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}vpngw-pip0"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_public_ip" "vpngw_pip1" {
  count               = var.vnet_config[0].enable_vpngw ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}vpngw-pip1"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_virtual_network_gateway" "vpngw" {
  count               = var.vnet_config[0].enable_vpngw ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}vpngw"
  location            = var.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = "VpnGw1"
  enable_bgp          = true
  active_active       = true

  ip_configuration {
    name                          = "${local.prefix}ip-config0"
    subnet_id                     = azurerm_subnet.this["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.vpngw_pip0[0].id
    private_ip_address_allocation = "Dynamic"
  }
  ip_configuration {
    name                          = "${local.prefix}ip-config1"
    subnet_id                     = azurerm_subnet.this["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.vpngw_pip1[0].id
    private_ip_address_allocation = "Dynamic"
  }

  bgp_settings {
    asn = var.vnet_config[0].vpngw_config[0].asn
    peering_addresses {
      ip_configuration_name = "${local.prefix}ip-config0"
      apipa_addresses       = try(var.vnet_config[0].vpngw_config.ip_config0_apipa_addresses, ["169.254.21.1"])
    }
    peering_addresses {
      ip_configuration_name = "${local.prefix}ip-config1"
      apipa_addresses       = try(var.vnet_config[0].vpngw_config.ip_config1_apipa_addresses, ["169.254.21.5"])
    }
  }
}

# ergw
#----------------------------

resource "azurerm_public_ip" "ergw_pip" {
  count               = var.vnet_config[0].enable_ergw ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}ergw-pip0"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_virtual_network_gateway" "ergw" {
  count               = var.vnet_config[0].enable_ergw ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}ergw"
  location            = var.location
  type                = "ExpressRoute"
  vpn_type            = "RouteBased"
  sku                 = "Standard"
  enable_bgp          = true
  active_active       = false
  ip_configuration {
    name                          = "${local.prefix}ip0"
    subnet_id                     = azurerm_subnet.this["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.ergw_pip[0].id
    private_ip_address_allocation = "Dynamic"
  }
}
