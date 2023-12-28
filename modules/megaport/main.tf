
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
  mcr_name    = each.value.name
  location_id = data.megaport_location.this[each.value.location].id
  router {
    port_speed    = each.value.port_speed
    requested_asn = each.value.requested_asn
  }
}

# connection
#----------------------------

resource "megaport_azure_connection" "this" {
  for_each   = { for connection in var.connection : connection.vxc_name => connection }
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
  }
}
