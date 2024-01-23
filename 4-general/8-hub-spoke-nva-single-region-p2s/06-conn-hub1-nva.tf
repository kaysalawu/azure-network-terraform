
####################################################
# branch2
####################################################

# vnet peering
#----------------------------

# branch2-to-hub1

resource "azurerm_virtual_network_peering" "branch2_to_hub1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-branch2-to-hub1-peering"
  virtual_network_name         = module.branch2.vnet.name
  remote_virtual_network_id    = module.hub1.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
  depends_on = [
    module.branch2,
    module.hub1,
  ]
}

# hub1-to-branch2

resource "azurerm_virtual_network_peering" "hub1_to_branch2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub1-to-branch2-peering"
  virtual_network_name         = module.hub1.vnet.name
  remote_virtual_network_id    = module.branch2.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    module.branch2,
    module.hub1,
  ]
}
