
####################################################
# inter-hub peering
####################################################

# peering
#----------------------------

# branch1-to-branch3

resource "azurerm_virtual_network_peering" "branch1_to_branch3_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-branch1-to-branch3-peering"
  virtual_network_name         = module.branch1.vnet.name
  remote_virtual_network_id    = module.branch3.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

# branch3-to-branch1

resource "azurerm_virtual_network_peering" "branch3_to_branch1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-branch3-to-branch1-peering"
  virtual_network_name         = module.branch3.vnet.name
  remote_virtual_network_id    = module.branch1.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
}

