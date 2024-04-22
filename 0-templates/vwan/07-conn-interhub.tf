
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

