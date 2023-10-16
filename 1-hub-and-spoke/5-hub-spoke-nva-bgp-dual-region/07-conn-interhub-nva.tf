
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
}

# hub2-to-hub1

resource "azurerm_virtual_network_peering" "hub2_to_hub1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub2-to-hub1-peering"
  virtual_network_name         = module.hub2.vnet.name
  remote_virtual_network_id    = module.hub1.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

####################################################
# udr
####################################################

# hub1

module "hub1_udr_appliance" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub1_prefix}nva"
  location               = local.hub1_location
  subnet_id              = module.hub1.subnets["${local.hub1_prefix}nva"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_nva_ilb_addr
  destinations           = local.hub1_appliance_udr_destinations
  depends_on             = [module.hub1, ]
}

# hub2

module "hub2_udr_applicance" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub2_prefix}nva"
  location               = local.hub2_location
  subnet_id              = module.hub2.subnets["${local.hub2_prefix}nva"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub1_nva_ilb_addr
  destinations           = local.hub2_appliance_udr_destinations
  depends_on             = [module.hub2, ]
}

####################################################
# dns
####################################################

locals {
  dns_zone_links_hub1_vnet = {
    "hub2" = module.hub2.vnet.id
  }
  dns_zone_links_hub2_vnet = {
    "hub1" = module.hub1.vnet.id
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_zone_links_hub1_vnet" {
  for_each              = local.dns_zone_links_hub1_vnet
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = "${local.prefix}${each.key}vnet-link"
  private_dns_zone_name = module.hub1.private_dns_zone.name
  virtual_network_id    = each.value
  registration_enabled  = false
  timeouts {
    create = "60m"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_zone_links_hub2_vnet" {
  for_each              = local.dns_zone_links_hub2_vnet
  resource_group_name   = azurerm_resource_group.rg.name
  name                  = "${local.prefix}${each.key}vnet-link"
  private_dns_zone_name = module.hub2.private_dns_zone.name
  virtual_network_id    = each.value
  registration_enabled  = false
  timeouts {
    create = "60m"
  }
}
