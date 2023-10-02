
locals {
  policy_ng_hubs_prod = templatefile("../../policies/net-man/ng-hubs-prod.json", {
    NETWORK_GROUP_ID = azurerm_network_manager_network_group.ng_hubs_prod.id
  })
  policy_cleanup_commands_hubs = [
    "az policy assignment delete -n ${local.prefix}-ng-hubs-prod",
    "az policy definition delete -n ${local.prefix}-ng-hubs-prod",
  ]
}

####################################################
# network groups
####################################################

resource "azurerm_network_manager_network_group" "ng_hubs_prod" {
  name               = "${local.prefix}-ng-hubs-prod"
  network_manager_id = azurerm_network_manager.netman.id
}

####################################################
# policy definitions
####################################################

resource "azurerm_policy_definition" "ng_hubs_prod" {
  name         = "${local.prefix}-ng-hubs-prod"
  policy_type  = "Custom"
  mode         = "Microsoft.Network.Data"
  display_name = "All hubs in prod region1"
  metadata     = templatefile("../../policies/net-man/metadata.json", {})
  policy_rule  = local.policy_ng_hubs_prod
}

####################################################
# policy assignments
####################################################

resource "azurerm_subscription_policy_assignment" "ng_hubs_prod" {
  name                 = "${local.prefix}-ng-hubs-prod"
  policy_definition_id = azurerm_policy_definition.ng_hubs_prod.id
  subscription_id      = data.azurerm_subscription.current.id
}

####################################################
# configuration
####################################################

# connectivity
#---------------------------

resource "azurerm_network_manager_connectivity_configuration" "conn_config_hubs" {
  name                  = "${local.prefix}-conn-config-hubs"
  network_manager_id    = azurerm_network_manager.netman.id
  connectivity_topology = "Mesh"
  applies_to_group {
    group_connectivity = "None"
    network_group_id   = azurerm_network_manager_network_group.ng_hubs_prod.id
  }
  depends_on = [
    module.hub1
  ]
}

####################################################
# deployment
####################################################

# connectivity

resource "azurerm_network_manager_deployment" "conn_config_hubs" {
  network_manager_id = azurerm_network_manager.netman.id
  location           = local.region1
  scope_access       = "Connectivity"
  configuration_ids = [
    azurerm_network_manager_connectivity_configuration.conn_config_hubs.id
  ]
  triggers = {
    connectivity_configuration_ids = azurerm_network_manager_connectivity_configuration.conn_config_hubs.id
  }
}

####################################################
# cleanup
####################################################

resource "null_resource" "policy_cleanup_hubs" {
  count = length(local.policy_cleanup_commands_hubs)
  triggers = {
    create = ":"
    delete = local.policy_cleanup_commands_hubs[count.index]
  }
  provisioner "local-exec" {
    command = self.triggers.create
  }
  provisioner "local-exec" {
    when    = destroy
    command = self.triggers.delete
  }
  depends_on = [
    azurerm_policy_definition.ng_hubs_prod,
    azurerm_subscription_policy_assignment.ng_hubs_prod,
  ]
}

####################################################
# output files
####################################################

locals {
  netman_files = {
    "output/policies/pol-ng-hubs.json" = local.policy_ng_hubs_prod
  }
}

resource "local_file" "netman_files" {
  for_each = local.netman_files
  filename = each.key
  content  = each.value
}
