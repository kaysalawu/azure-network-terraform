
####################################################
# spoke4
####################################################

# vnet peering
#----------------------------

# spoke4-to-hub2

resource "azurerm_virtual_network_peering" "spoke4_to_hub2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke4-to-hub2-peering"
  virtual_network_name         = module.spoke4.vnet.name
  remote_virtual_network_id    = module.hub2.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  depends_on = [
    module.spoke4,
    module.hub2,
  ]
}

# hub2-to-spoke4

resource "azurerm_virtual_network_peering" "hub2_to_spoke4_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub2-to-spoke4-peering"
  virtual_network_name         = module.hub2.vnet.name
  remote_virtual_network_id    = module.spoke4.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  depends_on = [
    module.spoke4,
    module.hub2,
  ]
}

# udr
#----------------------------

# main

module "spoke4_udr_main" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.spoke4_prefix}main"
  location       = local.spoke4_location
  subnet_id      = module.spoke4.subnets["MainSubnet"].id
  routes = [for r in local.spoke4_udr_main_routes : {
    name                   = r.name
    address_prefix         = r.address_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = r.next_hop_ip
  }]

  disable_bgp_route_propagation = true

  depends_on = [
    time_sleep.hub2,
  ]
}


####################################################
# hub2
####################################################

# udr
#----------------------------

# main

module "hub2_udr_main" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.hub2_prefix}main"
  location       = local.hub2_location
  subnet_id      = module.hub2.subnets["MainSubnet"].id
  routes = [for r in local.hub2_udr_main_routes : {
    name                   = r.name
    address_prefix         = r.address_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = r.next_hop_ip
  }]

  disable_bgp_route_propagation = true

  depends_on = [
    time_sleep.hub2,
  ]
}

####################################################
# output files
####################################################

locals {
  hub2_files = {}
}

resource "local_file" "hub2_files" {
  for_each = local.hub2_files
  filename = each.key
  content  = each.value
}

