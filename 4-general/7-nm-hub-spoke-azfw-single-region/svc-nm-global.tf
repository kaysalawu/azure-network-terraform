
####################################################
# network manager
####################################################

resource "azurerm_network_manager" "avnm" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.region1
  name                = "${local.prefix}-avnm"
  scope_accesses      = ["Connectivity", "SecurityAdmin"]
  description         = "global"
  scope {
    subscription_ids = [data.azurerm_subscription.current.id]
  }
}

