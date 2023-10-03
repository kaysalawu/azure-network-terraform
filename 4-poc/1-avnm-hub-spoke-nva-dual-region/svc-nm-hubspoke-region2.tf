
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
  network_manager_id    = azurerm_network_manager.netman.id
  connectivity_topology = "HubAndSpoke"
  hub {
    resource_id   = module.hub2.vnet.id
    resource_type = "Microsoft.Network/virtualNetworks"
  }
  applies_to_group {
    group_connectivity  = "None"
    network_group_id    = azurerm_network_manager_network_group.ng_spokes_prod_region2.id
    global_mesh_enabled = false
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
  network_manager_id = azurerm_network_manager.netman.id
  location           = local.region2
  scope_access       = "Connectivity"
  configuration_ids = [
    azurerm_network_manager_connectivity_configuration.conn_config_hub_spoke_region2.id
  ]
  triggers = {
    connectivity_configuration_ids = azurerm_network_manager_connectivity_configuration.conn_config_hub_spoke_region2.id
  }
}

####################################################
# cleanup
####################################################

resource "null_resource" "policy_cleanup_region2" {
  count = length(local.policy_cleanup_commands_region2)
  triggers = {
    create = ":"
    delete = local.policy_cleanup_commands_region2[count.index]
  }
  provisioner "local-exec" {
    command = self.triggers.create
  }
  provisioner "local-exec" {
    when    = destroy
    command = self.triggers.delete
  }
  depends_on = [
    azurerm_policy_definition.ng_spokes_prod_region2,
    azurerm_subscription_policy_assignment.ng_spokes_prod_region2,
  ]
}

####################################################
# output files
####################################################

locals {
  netman_files_region2 = {
    "output/policies/pol-ng-spokes.json" = local.policy_ng_spokes_prod_region2
  }
}

resource "local_file" "netman_files_region2" {
  for_each = local.netman_files_region2
  filename = each.key
  content  = each.value
}
