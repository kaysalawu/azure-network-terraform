
locals {
  policy_ng_spokes_prod_region2 = templatefile("../../policies/net-man/ng-spokes-prod-region.json", {
    NETWORK_GROUP_ID = azurerm_network_manager_network_group.ng_spokes_prod_region2.id
    LOCATION         = local.region2
  })
  policy_cleanup_commands_region2 = [
    "az policy assignment delete -n ${local.prefix}-ng-spokes-prod-region2",
    "az policy definition delete -n ${local.prefix}-ng-spokes-prod-region2",
  ]
}

####################################################
# network groups
####################################################

resource "azurerm_network_manager_network_group" "ng_spokes_prod_region2" {
  name               = "${local.prefix}-ng-spokes-prod-region2"
  network_manager_id = azurerm_network_manager.netman.id
}

####################################################
# policy definitions
####################################################

resource "azurerm_policy_definition" "ng_spokes_prod_region2" {
  name         = "${local.prefix}-ng-spokes-prod-region2"
  policy_type  = "Custom"
  mode         = "Microsoft.Network.Data"
  display_name = "All spokes in prod region2"
  metadata     = templatefile("../../policies/net-man/metadata.json", {})
  policy_rule  = local.policy_ng_spokes_prod_region2
}

####################################################
# policy assignments
####################################################

resource "azurerm_subscription_policy_assignment" "ng_spokes_prod_region2" {
  name                 = "${local.prefix}-ng-spokes-prod-region2"
  policy_definition_id = azurerm_policy_definition.ng_spokes_prod_region2.id
  subscription_id      = data.azurerm_subscription.current.id
}

####################################################
# configuration
####################################################

# connectivity
#---------------------------

resource "azurerm_network_manager_connectivity_configuration" "conn_config_hub_spoke_region2" {
  name                  = "${local.prefix}-conn-config-hub-spoke-region2"
  network_manager_id    = azurerm_network_manager.network_manager_instance.id
  connectivity_topology = "HubAndSpoke"
  hub {
    resource_id   = module.hub2.vnet.id
    resource_type = "Microsoft.Network/virtualNetworks"
  }
  applies_to_group {
    group_connectivity  = "DirectlyConnected"
    network_group_id    = azurerm_network_manager_network_group.ng_spokes_prod_region2.id
    global_mesh_enabled = true
    use_hub_gateway     = true
  }
  depends_on = [
    module.hub2
  ]
}

####################################################
# deployment
####################################################

# connectivity
#---------------------------

resource "azurerm_network_manager_deployment" "conn_config_hub_spoke_region2" {
  network_manager_id = azurerm_network_manager.network_manager_instance.id
  location           = local.region2
  scope_access       = "Connectivity"
  configuration_ids = [
    azurerm_network_manager_connectivity_configuration.conn_config_hub_spoke_region2.id
  ]
  triggers = {
    connectivity_configuration_ids = azurerm_network_manager_connectivity_configuration.conn_config_hub_spoke_region2.id
  }
}
