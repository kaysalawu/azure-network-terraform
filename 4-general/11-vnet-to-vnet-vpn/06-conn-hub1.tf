
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
    module.spoke1,
    module.hub1,
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
    module.spoke1,
    module.hub1,
  ]
}

# udr
#----------------------------

# main

# module "spoke1_udr_main" {
#   source         = "../../modules/route-table"
#   resource_group = azurerm_resource_group.rg.name
#   prefix         = "${local.spoke1_prefix}main"
#   location       = local.spoke1_location
#   subnet_ids     = [module.spoke1.subnets["MainSubnet"].id, ]
#   routes = [{
#     name           = "hub2"
#     address_prefix = [local.hub2_address_space.0, ]
#     next_hop_type  = "VirtualNetworkGateway"
#   }]

#   bgp_route_propagation_enabled = false

#   depends_on = [
#     time_sleep.hub1,
#   ]
# }

####################################################
# output files
####################################################

locals {
  hub1_files = {}
}

resource "local_file" "hub1_files" {
  for_each = local.hub1_files
  filename = each.key
  content  = each.value
}

