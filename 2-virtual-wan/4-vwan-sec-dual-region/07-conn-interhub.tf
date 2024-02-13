
####################################################
# dns zones
####################################################

locals {
  dns_zones_linked_to_hub1_vnet = { "hub2" = module.hub2.vnet.id }
  dns_zones_linked_to_hub2_vnet = { "hub1" = module.hub1.vnet.id }
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_zones_linked_to_hub1_vnet" {
  for_each              = local.dns_zones_linked_to_hub1_vnet
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = lower("${local.prefix}-${each.key}-vnet--link")
  private_dns_zone_name = module.common.private_dns_zones[local.region1_dns_zone].name
  virtual_network_id    = each.value
  registration_enabled  = false
  timeouts {
    create = "60m"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_zones_linked_to_hub2_vnet" {
  for_each              = local.dns_zones_linked_to_hub2_vnet
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = lower("${local.prefix}-${each.key}-vnet--link")
  private_dns_zone_name = module.common.private_dns_zones[local.region2_dns_zone].name
  virtual_network_id    = each.value
  registration_enabled  = false
  timeouts {
    create = "60m"
  }
}

