
# locations
#----------------------------

data "megaport_location" "this" {
  for_each = toset(var.megaport_locations)
  name     = each.value
  has_mcr  = true
}

# mcr
#----------------------------

resource "megaport_mcr" "this" {
  for_each    = { for mcr in var.mcr : mcr.name => mcr }
  mcr_name    = "${var.prefix}-${each.value.name}"
  location_id = data.megaport_location.this[each.value.location].id
  router {
    port_speed    = each.value.port_speed
    requested_asn = each.value.requested_asn
  }
}

# megaport
#----------------------------

resource "megaport_azure_connection" "this" {
  for_each   = { for c in var.connection : c.vxc_name => c }
  vxc_name   = each.value.vxc_name
  rate_limit = each.value.rate_limit

  a_end {
    port_id        = megaport_mcr.this[each.value.mcr_name].id
    requested_vlan = each.value.requested_vlan
  }

  csp_settings {
    service_key                   = each.value.service_key
    auto_create_private_peering   = each.value.auto_create_private_peering
    auto_create_microsoft_peering = each.value.auto_create_microsoft_peering

    dynamic "private_peering" {
      for_each = each.value.private_peering != null ? [each.value.private_peering] : []
      content {
        peer_asn         = lookup(each.value.private_peering, "peer_asn", null)
        primary_subnet   = lookup(each.value.private_peering, "primary_subnet", null)
        secondary_subnet = lookup(each.value.private_peering, "secondary_subnet", null)
        shared_key       = lookup(each.value.private_peering, "shared_key", null)
        requested_vlan   = lookup(each.value.private_peering, "requested_vlan", null)
      }
    }

    # dynamic "microsoft_peering" {
    #   for_each = each.value.microsoft_peering != null ? [1] : []
    #   content {
    #     peer_asn         = lookup(each.value.microsoft_peering, "peer_asn", null)
    #     primary_subnet   = lookup(each.value.microsoft_peering, "primary_subnet", null)
    #     secondary_subnet = lookup(each.value.microsoft_peering, "secondary_subnet", null)
    #     public_prefixes  = lookup(each.value.microsoft_peering, "public_prefixes", null)
    #     shared_key       = lookup(each.value.microsoft_peering, "shared_key", null)
    #     requested_vlan   = lookup(each.value.microsoft_peering, "requested_vlan", null)
    #   }
    # }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [a_end, ]
  }
}

# azure peering
#----------------------------

resource "azurerm_express_route_circuit_peering" "private" {
  for_each                      = { for c in var.connection : c.vxc_name => c if c.private_peering != null }
  resource_group_name           = var.resource_group
  peering_type                  = "AzurePrivatePeering"
  express_route_circuit_name    = each.value.circuit_name
  peer_asn                      = tolist(megaport_mcr.this[each.value.mcr_name].router)[0].assigned_asn
  primary_peer_address_prefix   = each.value.private_peering.primary_subnet
  secondary_peer_address_prefix = each.value.private_peering.secondary_subnet
  vlan_id                       = each.value.private_peering.requested_vlan
  ipv4_enabled                  = true

  # dynamic "ipv6" {
  #   for_each = each.value.private_peering[0].ipv6 != null ? [1] : []
  #   content {
  #     primary_peer_address_prefix   = "2002:db01::/126"
  #     secondary_peer_address_prefix = "2003:db01::/126"
  #     enabled                       = true
  #   }
  # }
  depends_on = [
    megaport_azure_connection.this,
  ]
}

# azure gateway connection
#----------------------------

resource "azurerm_virtual_network_gateway_connection" "private" {
  for_each                   = { for c in var.connection : c.vxc_name => c if c.private_peering != null }
  resource_group_name        = var.resource_group
  name                       = "${var.prefix}-${each.value.vxc_name}-private"
  location                   = var.location
  type                       = "ExpressRoute"
  virtual_network_gateway_id = each.value.gateway_connection.virtual_network_gateway_id
  authorization_key          = each.value.gateway_connection.authorization_key
  express_route_circuit_id   = each.value.gateway_connection.express_route_circuit_id
  depends_on = [
    megaport_azure_connection.this,
    azurerm_express_route_circuit_peering.private
  ]
}
