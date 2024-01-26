
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
# udr
####################################################

# hub1

module "hub1_appliance_udr" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.hub1_prefix}azfw"
  location       = local.hub1_location
  subnet_id      = module.hub1.subnets["AzureFirewallSubnet"].id
  routes = [for r in local.hub1_appliance_udr_destinations : {
    name                   = r.name
    address_prefix         = r.address_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = module.hub2.firewall_private_ip
  }]
  depends_on = [module.hub1, ]
}

# hub2

module "hub2_appliance_udr" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.hub2_prefix}azfw"
  location       = local.hub2_location
  subnet_id      = module.hub2.subnets["AzureFirewallSubnet"].id
  routes = [for r in local.hub2_appliance_udr_destinations : {
    name                   = r.name
    address_prefix         = r.address_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = module.hub1.firewall_private_ip
  }]
  depends_on = [module.hub2, ]
}

####################################################
# dns
####################################################

# locals {
#   dns_zone_links_hub1_vnet = {
#     "hub2" = module.hub2.vnet.id
#   }
#   dns_zone_links_hub2_vnet = {
#     "hub1" = module.hub1.vnet.id
#   }
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "dns_zone_links_hub1_vnet" {
#   for_each              = local.dns_zone_links_hub1_vnet
#   resource_group_name   = azurerm_resource_group.rg.name
#   name                  = "${local.prefix}-${each.key}-vnet-link"
#   private_dns_zone_name = module.hub1.private_dns_zone.name
#   virtual_network_id    = each.value
#   registration_enabled  = false
#   timeouts {
#     create = "60m"
#   }
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "dns_zone_links_hub2_vnet" {
#   for_each              = local.dns_zone_links_hub2_vnet
#   resource_group_name   = azurerm_resource_group.rg.name
#   name                  = "${local.prefix}-${each.key}-vnet-link"
#   private_dns_zone_name = module.hub2.private_dns_zone.name
#   virtual_network_id    = each.value
#   registration_enabled  = false
#   timeouts {
#     create = "60m"
#   }
# }
