
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
# static routes
####################################################

# hub1 firewall
#----------------------------

module "hub1_udr_firewall" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub1_prefix}azfw"
  location               = local.hub1_location
  subnet_id              = module.hub1.subnets["AzureFirewallSubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_firewall_ip
  destinations = concat(
    local.udr_azure_destinations_region2,
  )
  depends_on = [module.hub1, ]
}

# hub2 firewall
#----------------------------

module "hub2_udr_firewall" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub2_prefix}azfw"
  location               = local.hub2_location
  subnet_id              = module.hub2.subnets["AzureFirewallSubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub1_firewall_ip
  destinations = concat(
    local.udr_azure_destinations_region1,
  )
  depends_on = [module.hub2, ]
}

