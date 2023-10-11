
locals {
  policy_ng_spokes_prod_region1 = templatefile("../../policies/net-man/ng-spokes-prod-region.json", {
    NETWORK_GROUP_ID = azurerm_network_manager_network_group.ng_spokes_prod_region1.id
    LOCATION         = local.region1
  })
  policy_cleanup_commands_region1 = [
    "az policy assignment delete -n ${local.prefix}-ng-spokes-prod-region1",
    "az policy definition delete -n ${local.prefix}-ng-spokes-prod-region1",
  ]
}

resource "random_id" "policy_region1" {
  byte_length = 4
}

####################################################
# network groups
####################################################

resource "azurerm_network_manager_network_group" "ng_spokes_prod_region1" {
  name               = "${local.prefix}-ng-spokes-prod-region1"
  network_manager_id = azurerm_network_manager.netman.id
}

####################################################
# policy definitions
####################################################

resource "azurerm_policy_definition" "ng_spokes_prod_region1" {
  name         = "${local.prefix}-ng-spokes-prod-region1-${random_id.policy_region1.hex}"
  policy_type  = "Custom"
  mode         = "Microsoft.Network.Data"
  display_name = "All spokes in prod region1"
  metadata     = templatefile("../../policies/net-man/metadata.json", {})
  policy_rule  = local.policy_ng_spokes_prod_region1
}

####################################################
# policy assignments
####################################################

resource "azurerm_subscription_policy_assignment" "ng_spokes_prod_region1" {
  name                 = "${local.prefix}-ng-spokes-prod-region1-${random_id.policy_region1.hex}"
  policy_definition_id = azurerm_policy_definition.ng_spokes_prod_region1.id
  subscription_id      = data.azurerm_subscription.current.id
}

####################################################
# configuration
####################################################

# connectivity
#---------------------------

resource "azurerm_network_manager_connectivity_configuration" "conn_config_hub_spoke_region1" {
  name                  = "${local.prefix}-conn-config-hub-spoke-region1"
  network_manager_id    = azurerm_network_manager.netman.id
  connectivity_topology = "HubAndSpoke"
  hub {
    resource_id   = module.hub1.vnet.id
    resource_type = "Microsoft.Network/virtualNetworks"
  }
  applies_to_group {
    group_connectivity  = "None"
    network_group_id    = azurerm_network_manager_network_group.ng_spokes_prod_region1.id
    global_mesh_enabled = false
    use_hub_gateway     = true
  }
  depends_on = [
    module.hub1
  ]
}

####################################################
# deployment
####################################################

# connectivity

resource "azurerm_network_manager_deployment" "conn_config_hub_spoke_region1" {
  network_manager_id = azurerm_network_manager.netman.id
  location           = local.region1
  scope_access       = "Connectivity"
  configuration_ids = [
    azurerm_network_manager_connectivity_configuration.conn_config_hub_spoke_region1.id
  ]
  triggers = {
    connectivity_configuration_ids = azurerm_network_manager_connectivity_configuration.conn_config_hub_spoke_region1.id
  }
}

####################################################
# cleanup
####################################################

resource "null_resource" "policy_cleanup_region1" {
  count = length(local.policy_cleanup_commands_region1)
  triggers = {
    create = ":"
    delete = local.policy_cleanup_commands_region1[count.index]
  }
  provisioner "local-exec" {
    command = self.triggers.create
  }
  provisioner "local-exec" {
    when    = destroy
    command = self.triggers.delete
  }
  depends_on = [
    azurerm_policy_definition.ng_spokes_prod_region1,
    azurerm_subscription_policy_assignment.ng_spokes_prod_region1,
  ]
}

####################################################
# output files
####################################################

locals {
  netman_files_region1 = {
    "output/policies/pol-ng-spokes.json" = local.policy_ng_spokes_prod_region1
  }
}

resource "local_file" "netman_files_region1" {
  for_each = local.netman_files_region1
  filename = each.key
  content  = each.value
}
