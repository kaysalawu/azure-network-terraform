
# vwan
#----------------------------

resource "azurerm_virtual_wan" "vwan" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}-vwan"
  location            = local.region1
  type                = "Standard"

  allow_branch_to_branch_traffic = true
}


