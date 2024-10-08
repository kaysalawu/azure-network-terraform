
####################################################
# inter-hub peering
####################################################

# peering
#----------------------------

# hub1-to-hub2

resource "azurerm_virtual_network_peering" "hub1_to_hub2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub1-to-hub2-peering"
  virtual_network_name         = module.hub1.vnet.name
  remote_virtual_network_id    = module.hub2.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  depends_on = [
    azurerm_virtual_network_peering.spoke1_to_hub1_peering,
    azurerm_virtual_network_peering.spoke2_to_hub1_peering,
    azurerm_virtual_network_peering.hub1_to_spoke1_peering,
    azurerm_virtual_network_peering.hub1_to_spoke2_peering,
  ]
}

# hub2-to-hub1

resource "azurerm_virtual_network_peering" "hub2_to_hub1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub2-to-hub1-peering"
  virtual_network_name         = module.hub2.vnet.name
  remote_virtual_network_id    = module.hub1.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  depends_on = [
    azurerm_virtual_network_peering.spoke4_to_hub2_peering,
    azurerm_virtual_network_peering.spoke5_to_hub2_peering,
    azurerm_virtual_network_peering.hub2_to_spoke4_peering,
    azurerm_virtual_network_peering.hub2_to_spoke5_peering,
  ]
}

####################################################
# dns
####################################################

locals {
  vnets_linked_dns_zone_region1 = { "hub2" = module.hub2.vnet.id }
  vnets_linked_dns_zone_region2 = { "hub1" = module.hub1.vnet.id }
}

resource "azurerm_private_dns_zone_virtual_network_link" "region1" {
  for_each              = local.vnets_linked_dns_zone_region1
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = lower("${local.prefix}-${each.key}-vnet--link")
  private_dns_zone_name = module.common.private_dns_zones[local.region1_dns_zone].name
  virtual_network_id    = each.value
  registration_enabled  = false
  timeouts {
    create = "60m"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "region2" {
  for_each              = local.vnets_linked_dns_zone_region2
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = lower("${local.prefix}-${each.key}-vnet--link")
  private_dns_zone_name = module.common.private_dns_zones[local.region2_dns_zone].name
  virtual_network_id    = each.value
  registration_enabled  = false
  timeouts {
    create = "60m"
  }
}


####################################################
# ars
####################################################

# hub1

resource "azurerm_route_server_bgp_connection" "hub1_ars_bgp_conn" {
  name            = "${local.hub1_prefix}ars-bgp-conn"
  route_server_id = module.hub1.ars.id
  peer_asn        = local.hub1_nva_asn
  peer_ip         = local.hub1_nva_untrust_addr
}

# hub2

resource "azurerm_route_server_bgp_connection" "hub2_ars_bgp_conn" {
  name            = "${local.hub2_prefix}ars-bgp-conn"
  route_server_id = module.hub2.ars.id
  peer_asn        = local.hub2_nva_asn
  peer_ip         = local.hub2_nva_untrust_addr
}
