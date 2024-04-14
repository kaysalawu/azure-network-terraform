
locals {
  vnet_connections = [for c in var.circuits : c if c.connection_target == "vnet"]
  vwan_connections = [for c in var.circuits : c if c.connection_target == "vwan"]
}

# locations
#----------------------------

data "megaport_location" "this" {
  name    = var.megaport_location
  has_mcr = true
}

# express route circuits
#----------------------------

resource "azurerm_express_route_circuit" "this" {
  for_each              = { for c in var.circuits : c.name => c }
  resource_group_name   = var.resource_group
  name                  = each.value.name
  location              = each.value.location
  peering_location      = each.value.peering_location
  service_provider_name = each.value.service_provider_name
  bandwidth_in_mbps     = each.value.bandwidth_in_mbps
  sku {
    tier   = each.value.sku_tier
    family = each.value.sku_family
  }
}

resource "azurerm_express_route_circuit_authorization" "this" {
  for_each                   = { for c in var.circuits : c.name => c }
  resource_group_name        = var.resource_group
  name                       = each.value.name
  express_route_circuit_name = azurerm_express_route_circuit.this[each.value.name].name
}

# mcr
#----------------------------

resource "megaport_mcr" "this" {
  for_each    = { for mcr in var.mcr : mcr.name => mcr }
  mcr_name    = "${var.prefix}-${each.value.name}"
  location_id = data.megaport_location.this.id
  router {
    port_speed    = each.value.port_speed
    requested_asn = each.value.requested_asn
  }
}

# vxc (layer 2)
#----------------------------

# primary

resource "megaport_azure_connection" "this" {
  for_each   = { for c in var.circuits : c.name => c }
  vxc_name   = "${each.value.name}-pri"
  rate_limit = each.value.bandwidth_in_mbps

  a_end {
    port_id        = megaport_mcr.this[each.value.mcr_name].id
    requested_vlan = each.value.requested_vlan
  }

  csp_settings {
    service_key = azurerm_express_route_circuit.this[each.value.name].service_key
  }

  lifecycle {
    ignore_changes = [a_end, ]
  }
}

resource "time_sleep" "vxc_peering_wait" {
  create_duration  = "30s"
  destroy_duration = "60s"
  depends_on = [
    megaport_azure_connection.this
  ]
}

# peering (layer 3)
#----------------------------

resource "azurerm_express_route_circuit_peering" "this" {
  for_each                      = { for c in var.circuits : c.name => c }
  resource_group_name           = var.resource_group
  express_route_circuit_name    = each.value.name
  peering_type                  = each.value.peering_type
  peer_asn                      = [for mcr in var.mcr : mcr.requested_asn if mcr.name == each.value.mcr_name][0]
  primary_peer_address_prefix   = each.value.primary_peer_address_prefix
  secondary_peer_address_prefix = each.value.secondary_peer_address_prefix
  ipv4_enabled                  = each.value.ipv4_enabled
  vlan_id                       = each.value.requested_vlan

  dynamic "ipv6" {
    for_each = each.value.primary_peer_address_prefix_ipv6 == null || each.value.secondary_peer_address_prefix_ipv6 == null ? [] : [1]
    content {
      primary_peer_address_prefix   = each.value.primary_peer_address_prefix_ipv6
      secondary_peer_address_prefix = each.value.secondary_peer_address_prefix_ipv6
      enabled                       = true
    }
  }
  depends_on = [
    azurerm_express_route_circuit_authorization.this,
    time_sleep.vxc_peering_wait,
  ]
}

resource "time_sleep" "peering_connection_wait" {
  create_duration  = "30s"
  destroy_duration = "60s"
  depends_on = [
    azurerm_express_route_circuit_peering.this
  ]
}

# azure connection
#----------------------------

# virtual network

resource "azurerm_virtual_network_gateway_connection" "this" {
  count                      = length(local.vnet_connections)
  resource_group_name        = var.resource_group
  name                       = local.vnet_connections[count.index].name
  location                   = local.vnet_connections[count.index].location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = local.vnet_connections[count.index].virtual_network_gateway_id
  authorization_key          = azurerm_express_route_circuit_authorization.this[local.vnet_connections[count.index].name].authorization_key
  express_route_circuit_id   = azurerm_express_route_circuit.this[local.vnet_connections[count.index].name].id
  depends_on = [
    azurerm_express_route_circuit_authorization.this,
    megaport_azure_connection.this,
    time_sleep.peering_connection_wait,
  ]
}

# vwan

data "azurerm_express_route_circuit_peering" "private" {
  count                      = length(local.vwan_connections)
  resource_group_name        = var.resource_group
  express_route_circuit_name = local.vwan_connections[count.index].name
  peering_type               = local.vwan_connections[count.index].peering_type
  depends_on = [
    azurerm_express_route_circuit_authorization.this,
    megaport_azure_connection.this,
  ]
}

resource "azurerm_express_route_connection" "this" {
  count                            = length(local.vwan_connections)
  name                             = local.vwan_connections[count.index].name
  express_route_gateway_id         = local.vwan_connections[count.index].express_route_gateway_id
  express_route_circuit_peering_id = data.azurerm_express_route_circuit_peering.private[local.vwan_connections[count.index].name].id
  depends_on = [
    azurerm_express_route_circuit_peering.this,
    azurerm_express_route_circuit_authorization.this,
    megaport_azure_connection.this,
  ]
}
