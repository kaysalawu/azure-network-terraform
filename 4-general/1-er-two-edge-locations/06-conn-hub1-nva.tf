
####################################################
# spoke1
####################################################

# vnet peering
#----------------------------

# spoke1-to-hub1

resource "azurerm_virtual_network_peering" "spoke1_to_hub1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke1-to-hub1-peering"
  virtual_network_name         = module.spoke1.vnet.name
  remote_virtual_network_id    = module.hub1.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
  depends_on = [
    module.hub1.ergw
  ]
}

# hub1-to-spoke1

resource "azurerm_virtual_network_peering" "hub1_to_spoke1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub1-to-spoke1-peering"
  virtual_network_name         = module.hub1.vnet.name
  remote_virtual_network_id    = module.spoke1.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    module.hub1.ergw
  ]
}

# udr
#----------------------------

# main

module "spoke1_udr_main" {
  source                        = "../../modules/udr"
  resource_group                = azurerm_resource_group.rg.name
  prefix                        = "${local.spoke1_prefix}main"
  location                      = local.spoke1_location
  subnet_id                     = module.spoke1.subnets["MainSubnet"].id
  next_hop_type                 = "VirtualAppliance"
  next_hop_in_ip_address        = local.hub1_nva_ilb_addr
  disable_bgp_route_propagation = true

  destinations = merge(
    local.default_udr_destinations,
    { "hub1" = local.hub1_address_space[0] }
  )
  depends_on = [
    module.hub1,
  ]
}

####################################################
# spoke2
####################################################

# vnet peering
#----------------------------

# spoke2-to-hub1

resource "azurerm_virtual_network_peering" "spoke2_to_hub1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke2-to-hub1-peering"
  virtual_network_name         = module.spoke2.vnet.name
  remote_virtual_network_id    = module.hub1.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
  depends_on = [
    module.hub1.s2s_vpngw
  ]
}

# hub1-to-spoke2

resource "azurerm_virtual_network_peering" "hub1_to_spoke2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub1-to-spoke2-peering"
  virtual_network_name         = module.hub1.vnet.name
  remote_virtual_network_id    = module.spoke2.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    module.hub1.s2s_vpngw
  ]
}

# udr
#----------------------------

# main

module "spoke2_udr_main" {
  source                        = "../../modules/udr"
  resource_group                = azurerm_resource_group.rg.name
  prefix                        = "${local.spoke2_prefix}main"
  location                      = local.spoke2_location
  subnet_id                     = module.spoke2.subnets["MainSubnet"].id
  next_hop_type                 = "VirtualAppliance"
  next_hop_in_ip_address        = local.hub1_nva_ilb_addr
  disable_bgp_route_propagation = true

  destinations = merge(
    local.default_udr_destinations,
    { "hub1" = local.hub1_address_space[0] }
  )
  depends_on = [
    module.hub1,
  ]
}

####################################################
# hub1
####################################################

# udr
#----------------------------

# gateway

module "hub1_udr_gateway" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub1_prefix}gateway"
  location               = local.hub1_location
  subnet_id              = module.hub1.subnets["GatewaySubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub1_nva_ilb_addr
  destinations           = local.hub1_gateway_udr_destinations
  depends_on = [
    module.hub1,
  ]
}

# main

module "hub1_udr_main" {
  source                        = "../../modules/udr"
  resource_group                = azurerm_resource_group.rg.name
  prefix                        = "${local.hub1_prefix}main"
  location                      = local.hub1_location
  subnet_id                     = module.hub1.subnets["MainSubnet"].id
  next_hop_type                 = "VirtualAppliance"
  next_hop_in_ip_address        = local.hub1_nva_ilb_addr
  disable_bgp_route_propagation = true

  destinations = merge(
    local.default_udr_destinations,
    {
      "spoke1" = local.spoke1_address_space[0]
      "spoke2" = local.spoke2_address_space[0]
    }
  )
  depends_on = [
    module.hub1,
  ]
}

####################################################
# output files
####################################################

locals {
  hub1_files = {
    "output/hub1-linux-nva.sh" = local.hub1_linux_nva_init
  }
}

resource "local_file" "hub1_files" {
  for_each = local.hub1_files
  filename = each.key
  content  = each.value
}

