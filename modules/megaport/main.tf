
locals {
  vnet_connections = { for c in var.gateway_connections : "${c.virtual_network_gateway_name}--${c.express_route_circuit_name}" => c if c.virtual_network_gateway_name != null && var.deploy }
  vwan_connections = { for c in var.gateway_connections : "${c.express_route_gateway_name}--${c.express_route_circuit_name}" => c if c.express_route_gateway_name != null && var.deploy }
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
  for_each              = { for c in var.circuits : c.name => c if var.deploy }
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
  for_each    = { for mcr in var.mcr : mcr.name => mcr if var.deploy }
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
  for_each   = { for c in var.circuits : c.name => c if var.deploy }
  vxc_name   = "${each.value.name}-pri"
  rate_limit = each.value.bandwidth_in_mbps

  a_end {
    port_id        = megaport_mcr.this[each.value.mcr_name].id
    requested_vlan = each.value.requested_vlan
  }

  csp_settings {
    service_key                 = azurerm_express_route_circuit.this[each.value.name].service_key
    auto_create_private_peering = each.value.mcr_config.enable_auto_peering

    # private_peering block:
    # Megaport creates the layer3 config on BOTH megaport and azure sides.
    # This means azurerm_express_route_circuit_peering resource will not be used - as this is the azure equivalent of creating peering on both sides.
    # Either let megaport OR azure configure both sides, not both.
    dynamic "private_peering" {
      for_each = each.value.mcr_config.create_private_peering ? [1] : []
      content {
        peer_asn         = [for mcr in var.mcr : mcr.requested_asn if mcr.name == each.value.mcr_name][0]
        primary_subnet   = each.value.primary_peer_address_prefix_ipv4
        secondary_subnet = each.value.secondary_peer_address_prefix_ipv4
        requested_vlan   = each.value.requested_vlan
      }
    }
  }
  lifecycle {
    ignore_changes = [a_end, ]
  }
}

resource "time_sleep" "wait_for_primary" {
  create_duration = "30s"
  depends_on = [
    megaport_azure_connection.primary,
  ]
}

# secondary

resource "megaport_azure_connection" "secondary" {
  for_each   = { for c in var.circuits : c.name => c if var.deploy }
  vxc_name   = "${each.value.name}-sec"
  rate_limit = each.value.bandwidth_in_mbps

  a_end {
    port_id        = megaport_mcr.this[each.value.mcr_name].id
    requested_vlan = each.value.requested_vlan
  }
  csp_settings {
    service_key                 = azurerm_express_route_circuit.this[each.value.name].service_key
    auto_create_private_peering = each.value.mcr_config.enable_auto_peering

    # private_peering block:
    # Megaport creates the layer3 config on BOTH megaport and azure sides.
    # This means azurerm_express_route_circuit_peering resource will not be used - as this is the azure equivalent of creating peering on both sides.
    # Either let megaport OR azure configure both sides, not both.
    dynamic "private_peering" {
      for_each = each.value.mcr_config.create_private_peering ? [1] : []
      content {
        peer_asn         = [for mcr in var.mcr : mcr.requested_asn if mcr.name == each.value.mcr_name][0]
        primary_subnet   = each.value.primary_peer_address_prefix_ipv4
        secondary_subnet = each.value.secondary_peer_address_prefix_ipv4
        requested_vlan   = each.value.requested_vlan
      }
    }
  }

  lifecycle {
    ignore_changes = [a_end, ]
  }
  depends_on = [
    megaport_azure_connection.primary,
    time_sleep.wait_for_primary,
  ]
}

# peering
#----------------------------

# Azure creates the layer2 and layer3 config on BOTH azure and megaport sides.
# This means megaport_azure_connection "private_peering" block will not be used - as this is the megaport equivalent of creating peering on both sides.
# Either let megaport OR azure configure both sides, not both.
resource "azurerm_express_route_circuit_peering" "this" {
  for_each                      = { for c in var.circuits : c.name => c if c.mcr_config.create_private_peering == false && var.deploy }
  resource_group_name           = var.resource_group
  express_route_circuit_name    = each.value.name
  peering_type                  = each.value.peering_type
  peer_asn                      = [for mcr in var.mcr : mcr.requested_asn if mcr.name == each.value.mcr_name][0]
  primary_peer_address_prefix   = each.value.primary_peer_address_prefix_ipv4
  secondary_peer_address_prefix = each.value.secondary_peer_address_prefix_ipv4
  ipv4_enabled                  = each.value.azure_config.create_ipv4_peering
  vlan_id                       = each.value.requested_vlan

  dynamic "ipv6" {
    for_each = each.value.azure_config.create_ipv6_peering ? [1] : []
    content {
      primary_peer_address_prefix   = each.value.primary_peer_address_prefix_ipv6
      secondary_peer_address_prefix = each.value.secondary_peer_address_prefix_ipv6
      enabled                       = true
    }
  }
  depends_on = [
    megaport_azure_connection.primary,
    megaport_azure_connection.secondary,
  ]
}

# gateway connections
#----------------------------

# time sleep

resource "time_sleep" "wait_for_peering" {
  count            = var.deploy ? 1 : 0
  create_duration  = "1m"
  destroy_duration = "1m"
  depends_on = [
    megaport_azure_connection.primary,
    megaport_azure_connection.secondary,
    azurerm_express_route_circuit_peering.this,
  ]
}

# vnet

data "azurerm_virtual_network_gateway" "vnet" {
  for_each            = var.deploy ? local.vnet_connections : {}
  resource_group_name = var.resource_group
  name                = each.value.virtual_network_gateway_name
  depends_on = [
    time_sleep.wait_for_peering[0],
  ]
}

resource "azurerm_express_route_circuit_authorization" "vnet" {
  for_each                   = var.deploy ? local.vnet_connections : {}
  resource_group_name        = var.resource_group
  name                       = "${each.key}--auth"
  express_route_circuit_name = azurerm_express_route_circuit.this[each.value.express_route_circuit_name].name
}

resource "azurerm_virtual_network_gateway_connection" "vnet" {
  for_each                   = var.deploy ? local.vnet_connections : {}
  resource_group_name        = var.resource_group
  name                       = "${each.key}--conn"
  location                   = azurerm_express_route_circuit.this[each.value.express_route_circuit_name].location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = data.azurerm_virtual_network_gateway.vnet[each.key].id
  authorization_key          = azurerm_express_route_circuit_authorization.vnet[each.key].authorization_key
  express_route_circuit_id   = azurerm_express_route_circuit.this[each.value.express_route_circuit_name].id
  shared_key                 = each.value.shared_key
  depends_on = [
    time_sleep.wait_for_peering[0],
  ]
}

# vwan

resource "azurerm_express_route_circuit_authorization" "vwan" {
  for_each                   = var.deploy ? local.vwan_connections : {}
  resource_group_name        = var.resource_group
  name                       = "${each.key}--auth"
  express_route_circuit_name = azurerm_express_route_circuit.this[each.value.express_route_circuit_name].name
  depends_on = [
    megaport_azure_connection.primary,
    megaport_azure_connection.secondary,
    azurerm_express_route_circuit_peering.this,
  ]
}

# resource "azapi_resource" "vwan_connection" {
#   for_each  = var.deploy ? local.vwan_connections : {}
#   type      = "Microsoft.Network/expressRouteGateways/expressRouteConnections@2023-11-01"
#   parent_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group}/providers/Microsoft.Network/expressRouteGateways/${each.value.express_route_gateway_name}"
#   name      = "${each.key}--conn"

#   body = jsonencode({
#     properties = {
#       expressRouteCircuitPeering = {
#         id = azurerm_express_route_circuit_peering.this[each.value.express_route_circuit_name].id
#       }
#       authorizationKey     = azurerm_express_route_circuit_authorization.vwan[each.key].authorization_key
#       routingConfiguration = {}
#     }
#   })
#   schema_validation_enabled = false
#   depends_on = [
#     megaport_azure_connection.primary,
#     megaport_azure_connection.secondary,
#     azurerm_express_route_circuit_peering.this,
#   ]
# }

resource "azurerm_express_route_connection" "vwan" {
  for_each                         = var.deploy ? local.vwan_connections : {}
  name                             = "${each.key}--conn"
  express_route_gateway_id         = "/subscriptions/${data.azurerm_subscription.current.subscription_id}/resourceGroups/${var.resource_group}/providers/Microsoft.Network/expressRouteGateways/${each.value.express_route_gateway_name}"
  express_route_circuit_peering_id = azurerm_express_route_circuit_peering.this[each.value.express_route_circuit_name].id
  authorization_key                = azurerm_express_route_circuit_authorization.vwan[each.key].authorization_key

  routing {
    associated_route_table_id = each.value.associated_route_table_id
    inbound_route_map_id      = each.value.inbound_route_map_id
    outbound_route_map_id     = each.value.outbound_route_map_id

    dynamic "propagated_route_table" {
      for_each = each.value.propagated_route_table != null ? each.value.propagated_route_table : []
      content {
        labels          = propagated_route_table.value.labels
        route_table_ids = propagated_route_table.value.route_table_ids
      }
    }
  }

  depends_on = [
    megaport_azure_connection.primary,
    megaport_azure_connection.secondary,
    azurerm_express_route_circuit_peering.this,
  ]
}

# ###################################################
# # dashboard
# ###################################################

locals {
  dashboard_vars = { for c in var.circuits : c.name => templatefile("${path.module}/dashboard/dashboard.json", {
    ER_CIRCUIT_ID = azurerm_express_route_circuit.this[c.name].id
    }) if var.deploy
  }
}

resource "azurerm_portal_dashboard" "express_route" {
  for_each             = var.deploy ? local.dashboard_vars : {}
  resource_group_name  = var.resource_group
  location             = var.azure_location
  name                 = "${each.key}-dashb"
  dashboard_properties = each.value
}
