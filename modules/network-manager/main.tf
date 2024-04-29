
locals {
  prefix = var.prefix == "" ? "" : format("%s-", var.prefix)
}

####################################################
# network manager
####################################################

resource "azurerm_network_manager" "this" {
  count               = var.use_azapi ? 0 : 1
  resource_group_name = var.resource_group_name
  location            = var.location
  name                = "${local.prefix}-nm"
  description         = var.description
  scope_accesses      = var.scope_accesses
  scope {
    subscription_ids     = var.scope_subscription_ids
    management_group_ids = var.scope_management_group_ids
  }
}

# azapi

resource "azapi_resource" "azurerm_network_manager" {
  count     = var.use_azapi ? 1 : 0
  type      = "Microsoft.Network/networkManagers@2022-09-01"
  name      = "${local.prefix}-nm"
  parent_id = data.resource_group.this.id
  location  = local.region1

  body = jsonencode({
    properties = {
      description = "global"
      networkManagerScopeAccesses = [
        "Connectivity",
        "SecurityAdmin",
        "Routing",
      ]
      networkManagerScopes = {
        subscriptions    = var.scope_subscription_ids
        managementGroups = var.scope_management_group_ids
      }
    }
  })
  schema_validation_enabled = false
  depends_on = [
    azurerm_network_manager.this
  ]
}
