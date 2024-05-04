
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

# vxc
#----------------------------

# primary

resource "megaport_azure_connection" "primary" {
  for_each   = { for c in var.circuits : c.name => c }
  vxc_name   = "${each.value.name}-pri"
  rate_limit = each.value.bandwidth_in_mbps

  a_end {
    port_id        = megaport_mcr.this[each.value.mcr_name].id
    requested_vlan = each.value.requested_vlan
  }

  csp_settings {
    service_key                 = azurerm_express_route_circuit.this[each.value.name].service_key
    auto_create_private_peering = each.value.auto_create_private_peering
  }

  lifecycle {
    ignore_changes = [a_end, ]
  }
}

# secondary

resource "megaport_azure_connection" "secondary" {
  for_each   = { for c in var.circuits : c.name => c }
  vxc_name   = "${each.value.name}-sec"
  rate_limit = each.value.bandwidth_in_mbps

  a_end {
    port_id        = megaport_mcr.this[each.value.mcr_name].id
    requested_vlan = each.value.requested_vlan
  }

  csp_settings {
    service_key                 = azurerm_express_route_circuit.this[each.value.name].service_key
    auto_create_private_peering = each.value.auto_create_private_peering
  }

  lifecycle {
    ignore_changes = [a_end, ]
  }
}

# peering
#----------------------------

resource "azurerm_express_route_circuit_peering" "this" {
  for_each                      = { for c in var.circuits : c.name => c }
  resource_group_name           = var.resource_group
  express_route_circuit_name    = each.value.name
  peering_type                  = each.value.peering_type
  peer_asn                      = [for mcr in var.mcr : mcr.requested_asn if mcr.name == each.value.mcr_name][0]
  primary_peer_address_prefix   = each.value.ipv4_config.primary_peer_address_prefix
  secondary_peer_address_prefix = each.value.ipv4_config.secondary_peer_address_prefix
  ipv4_enabled                  = true
  vlan_id                       = each.value.requested_vlan

  dynamic "ipv6" {
    for_each = each.value.ipv6_config.create_azure_private_peering ? [1] : []
    content {
      primary_peer_address_prefix   = each.value.ipv6_config.primary_peer_address_prefix
      secondary_peer_address_prefix = each.value.ipv6_config.secondary_peer_address_prefix
      enabled                       = true
    }
  }
  depends_on = [
    megaport_azure_connection.primary,
    azurerm_express_route_circuit_authorization.this,
  ]
}

# gateway connections
#----------------------------

resource "azurerm_express_route_circuit_authorization" "this" {
  for_each                   = { for c in var.circuits : c.name => c if c.virtual_network_gateway_id != null }
  resource_group_name        = var.resource_group
  name                       = each.value.name
  express_route_circuit_name = azurerm_express_route_circuit.this[each.value.name].name
}

resource "azurerm_virtual_network_gateway_connection" "vnet" {
  for_each                   = { for c in var.circuits : c.name => c if c.virtual_network_gateway_id != null }
  resource_group_name        = var.resource_group
  name                       = each.value.name
  location                   = var.azure_location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = each.value.virtual_network_gateway_id
  authorization_key          = azurerm_express_route_circuit_authorization.this[each.value.name].authorization_key
  express_route_circuit_id   = azurerm_express_route_circuit.this[each.value.name].id
  depends_on = [
    megaport_azure_connection.primary,
    azurerm_express_route_circuit_authorization.this,
  ]
}

# dashboard
# ----------------------------

locals {
  dashboard_vars = { for c in var.circuits :
    c.name => templatefile("${path.module}/dashboard/dashboard.json", {
      ER_CIRCUIT_ID = azurerm_express_route_circuit.this[c.name].id
    })
  }
}

resource "azurerm_portal_dashboard" "hub2_er" {
  for_each             = local.dashboard_vars
  resource_group_name  = var.resource_group
  location             = var.azure_location
  name                 = "${each.key}-dashb"
  dashboard_properties = each.value
}
