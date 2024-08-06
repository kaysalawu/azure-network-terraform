
####################################################
# vnet-to-vnet vpn
####################################################

# vpn
#----------------------------

# hub1-to-hub2

resource "azurerm_virtual_network_gateway_connection" "hub1_to_hub2" {
  resource_group_name             = azurerm_resource_group.rg.name
  name                            = "${local.prefix}-hub1-to-hub2-v2v-conn"
  location                        = local.hub1_location
  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = module.hub1.s2s_vpngw.id
  peer_virtual_network_gateway_id = module.hub2.s2s_vpngw.id
  shared_key                      = local.psk
}

# hub2-to-hub1

resource "azurerm_virtual_network_gateway_connection" "hub2_to_hub1" {
  resource_group_name             = azurerm_resource_group.rg.name
  name                            = "${local.prefix}-hub2-to-hub1-v2v-conn"
  location                        = local.hub2_location
  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = module.hub2.s2s_vpngw.id
  peer_virtual_network_gateway_id = module.hub1.s2s_vpngw.id
  shared_key                      = local.psk
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

