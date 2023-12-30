
# locations
#----------------------------

data "megaport_location" "this" {
  name    = var.megaport_location
  has_mcr = true
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

# azure peering
#----------------------------

resource "azurerm_express_route_circuit_peering" "private" {
  for_each                      = { for c in var.circuits : c.name => c }
  resource_group_name           = var.resource_group
  peering_type                  = "AzurePrivatePeering"
  express_route_circuit_name    = azurerm_express_route_circuit.this[each.value.name].name
  peer_asn                      = tolist(megaport_mcr.this[each.value.mcr_name].router)[0].assigned_asn
  primary_peer_address_prefix   = each.value.primary_peer_address_prefix
  secondary_peer_address_prefix = each.value.secondary_peer_address_prefix
  vlan_id                       = each.value.requested_vlan
  ipv4_enabled                  = true
}

# vxc
#----------------------------

resource "megaport_azure_connection" "this" {
  for_each   = { for c in var.circuits : c.name => c }
  vxc_name   = each.value.name
  rate_limit = each.value.bandwidth_in_mbps

  a_end {
    port_id        = megaport_mcr.this[each.value.mcr_name].id
    requested_vlan = each.value.requested_vlan
  }

  csp_settings {
    service_key                   = azurerm_express_route_circuit.this[each.value.name].service_key
    auto_create_private_peering   = each.value.auto_create_private_peering
    auto_create_microsoft_peering = each.value.auto_create_microsoft_peering
  }

  lifecycle {
    ignore_changes = [a_end, csp_settings, ]
  }
  depends_on = [
    azurerm_express_route_circuit_peering.private
  ]
}

# azure connection
#----------------------------

# virtual network

resource "azurerm_virtual_network_gateway_connection" "this" {
  for_each                   = { for c in var.circuits : c.name => c if c.virtual_network_gateway_id != null }
  resource_group_name        = var.resource_group
  name                       = each.value.name
  location                   = each.value.location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = each.value.virtual_network_gateway_id
  authorization_key          = azurerm_express_route_circuit_authorization.this[each.value.name].authorization_key
  express_route_circuit_id   = azurerm_express_route_circuit.this[each.value.name].id
  depends_on = [
    azurerm_express_route_circuit.this,
    azurerm_express_route_circuit_authorization.this,
    azurerm_express_route_circuit_peering.private,
    megaport_azure_connection.this,
  ]
}

# virtual wan

resource "azurerm_express_route_connection" "this" {
  for_each                         = { for c in var.circuits : c.name => c if c.express_route_gateway_id != null }
  name                             = each.value.name
  express_route_gateway_id         = each.value.express_route_gateway_id
  express_route_circuit_peering_id = azurerm_express_route_circuit_peering.private[each.value.name].id
  depends_on = [
    azurerm_express_route_circuit.this,
    azurerm_express_route_circuit_authorization.this,
    azurerm_express_route_circuit_peering.private,
    megaport_azure_connection.this,
  ]
}
