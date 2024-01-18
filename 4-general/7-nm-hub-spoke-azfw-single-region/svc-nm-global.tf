
# locals {
#   policy_ng_spokes_prod = templatefile("../../policies/avnm/ng-spokes-prod.json", {
#     NETWORK_GROUP_ID = azurerm_network_manager_network_group.ng_spokes_prod.id
#   })
#   policy_cleanup_commands_global = [
#     "az policy assignment delete -n ${local.prefix}-ng-spokes-prod",
#     "az policy definition delete -n ${local.prefix}-ng-spokes-prod",
#   ]
# }

data "azurerm_subscription" "current" {
}

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
