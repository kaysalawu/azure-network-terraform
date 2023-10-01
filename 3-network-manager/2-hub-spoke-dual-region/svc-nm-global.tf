
locals {
  policy_ng_spokes_prod = templatefile("../../policies/net-man/ng-spokes-prod.json", {
    NETWORK_GROUP_ID = azurerm_network_manager_network_group.ng_spokes_prod.id
  })
  policy_cleanup_commands_global = [
    "az policy assignment delete -n ${local.prefix}-ng-spokes-prod",
    "az policy definition delete -n ${local.prefix}-ng-spokes-prod",
  ]
}

####################################################
# network manager
####################################################

resource "azurerm_network_manager" "netman" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.region1
  name                = "${local.prefix}-netman"
  scope_accesses      = ["Connectivity", "SecurityAdmin"]
  description         = "global"
  scope {
    subscription_ids = [data.azurerm_subscription.current.id]
  }
}

####################################################
# network groups
####################################################

resource "azurerm_network_manager_network_group" "ng_spokes_prod" {
  name               = "${local.prefix}-ng-spokes-prod"
  network_manager_id = azurerm_network_manager.netman.id
}

####################################################
# policy definitions
####################################################

resource "azurerm_policy_definition" "ng_spokes_prod" {
  name         = "${local.prefix}-ng-spokes-prod"
  policy_type  = "Custom"
  mode         = "Microsoft.Network.Data"
  display_name = "All spokes in prod"
  metadata     = templatefile("../../policies/net-man/metadata.json", {})
  policy_rule  = local.policy_ng_spokes_prod
}

####################################################
# policy assignments
####################################################

resource "azurerm_subscription_policy_assignment" "ng_spokes_prod" {
  name                 = "${local.prefix}-ng-spokes-prod"
  policy_definition_id = azurerm_policy_definition.ng_spokes_prod.id
  subscription_id      = data.azurerm_subscription.current.id
}

####################################################
# configuration
####################################################

# connectivity

resource "azurerm_network_manager_connectivity_configuration" "conn_config_spokes" {
  name                  = "${local.prefix}-conn-config-spokes"
  network_manager_id    = azurerm_network_manager.netman.id
  connectivity_topology = "Mesh"
  applies_to_group {
    group_connectivity = "None"
    network_group_id   = azurerm_network_manager_network_group.ng_spokes_prod.id
  }
}

####################################################
# deployment
####################################################

# connectivity

resource "azurerm_network_manager_deployment" "conn_config_spokes" {
  network_manager_id = azurerm_network_manager.netman.id
  location           = local.region1
  scope_access       = "Connectivity"
  configuration_ids = [
    azurerm_network_manager_connectivity_configuration.conn_config_spokes.id
  ]
  triggers = {
    connectivity_configuration_ids = azurerm_network_manager_connectivity_configuration.conn_config_spokes.id
  }
}

####################################################
# cleanup
####################################################

resource "null_resource" "policy_cleanup_global" {
  count = length(local.policy_cleanup_commands_global)
  triggers = {
    create = ":"
    delete = local.policy_cleanup_commands_global[count.index]
  }
  provisioner "local-exec" {
    command = self.triggers.create
  }
  provisioner "local-exec" {
    when    = destroy
    command = self.triggers.delete
  }
  depends_on = [
    azurerm_policy_definition.ng_spokes_prod,
    azurerm_subscription_policy_assignment.ng_spokes_prod,
  ]
}

####################################################
# output files
####################################################

locals {
  netman_files = {
    "output/policies/pol-ng-spokes.json" = local.policy_ng_spokes_prod
  }
}

resource "local_file" "netman_files" {
  for_each = local.netman_files
  filename = each.key
  content  = each.value
}
