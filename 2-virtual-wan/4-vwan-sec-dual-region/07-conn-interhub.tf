
####################################################
# dns zones
####################################################

locals {
  dns_links_hub1_vnet = {
    "hub2"   = module.hub2.vnet.id
    "spoke4" = module.spoke4.vnet.id
    "spoke5" = module.spoke5.vnet.id
  }
  dns_links_hub2_vnet = {
    "hub1"   = module.hub1.vnet.id
    "spoke1" = module.spoke1.vnet.id
    "spoke2" = module.spoke2.vnet.id
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_links_hub1_vnet" {
  for_each              = local.dns_links_hub1_vnet
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = "${local.prefix}${each.key}vnet-link"
  private_dns_zone_name = module.hub1.private_dns_zone.name
  virtual_network_id    = each.value
  registration_enabled  = false
  timeouts {
    create = "60m"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_links_hub2_vnet" {
  for_each              = local.dns_links_hub2_vnet
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = "${local.prefix}${each.key}vnet-link"
  private_dns_zone_name = module.hub2.private_dns_zone.name
  virtual_network_id    = each.value
  registration_enabled  = false
  timeouts {
    create = "60m"
  }
}

####################################################
# private dns resolver
####################################################

# dns resolver links

# resource "azurerm_private_dns_resolver_virtual_network_link" "hub1" {
#   for_each                  = local.hub1_private_dns_ruleset_links
#   name                      = "${module.hub1.private_dns_forwarding_ruleset.name}-${each.key}-vnet-link}"
#   dns_forwarding_ruleset_id = module.hub1.private_dns_forwarding_ruleset.id
#   virtual_network_id        = each.value
# }

