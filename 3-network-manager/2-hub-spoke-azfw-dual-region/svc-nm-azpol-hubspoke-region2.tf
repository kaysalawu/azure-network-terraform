
locals {
  policy_ng_spokes_prod_region2 = templatefile("../../policies/avnm/ng-spokes-prod-region.json", {
    NETWORK_GROUP_ID = azurerm_network_manager_network_group.ng_spokes_prod_region2.id
    LOCATION         = local.region2
    LAB_ID           = local.prefix
    ENV              = "prod"
    NODE_TYPE        = "spoke"
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
  network_manager_id = azurerm_network_manager.avnm.id
  description        = "All spokes in prod region2"
}

####################################################
# policy definitions
####################################################

resource "azurerm_policy_definition" "ng_spokes_prod_region2" {
  name         = "${local.prefix}-ng-spokes-prod-region2"
  policy_type  = "Custom"
  mode         = "Microsoft.Network.Data"
  display_name = "All spokes in prod region2"
  metadata     = templatefile("../../policies/avnm/metadata.json", {})
  policy_rule  = local.policy_ng_spokes_prod_region2
}

####################################################
# policy assignments
####################################################

resource "azurerm_resource_group_policy_assignment" "ng_spokes_prod_region2" {
  name                 = "${local.prefix}-ng-spokes-prod-region2"
  policy_definition_id = azurerm_policy_definition.ng_spokes_prod_region2.id
  resource_group_id    = azurerm_resource_group.rg.id
}

####################################################
# configuration
####################################################

# connectivity
#---------------------------

resource "azurerm_network_manager_connectivity_configuration" "conn_config_hub_spoke_region2" {
  name                  = "${local.prefix}-conn-config-hub-spoke-region2"
  network_manager_id    = azurerm_network_manager.avnm.id
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
# security
####################################################

resource "azurerm_network_manager_security_admin_configuration" "secadmin_config_region2" {
  name               = "${local.prefix}-secadmin-config-region2"
  network_manager_id = azurerm_network_manager.avnm.id
}

resource "azurerm_network_manager_admin_rule_collection" "secadmin_rule_col_region2" {
  name                            = "${local.prefix}-secadmin-rule-col-region2"
  security_admin_configuration_id = azurerm_network_manager_security_admin_configuration.secadmin_config_region2.id
  network_group_ids = [
    azurerm_network_manager_network_group.ng_spokes_prod_region2.id
  ]
}

resource "azurerm_network_manager_admin_rule" "secadmin_rules_region2" {
  for_each                 = local.secadmin_rules_global
  name                     = "${local.prefix}-secadmin-rules-${each.key}"
  admin_rule_collection_id = azurerm_network_manager_admin_rule_collection.secadmin_rule_col_region2.id
  description              = each.value.description
  action                   = each.value.action
  direction                = each.value.direction
  priority                 = each.value.priority
  protocol                 = each.value.protocol
  source_port_ranges       = each.value.destination_port_ranges

  dynamic "source" {
    for_each = each.value.source
    content {
      address_prefix_type = source.value.address_prefix_type
      address_prefix      = source.value.address_prefix
    }
  }

  dynamic "destination" {
    for_each = each.value.destinations
    content {
      address_prefix_type = destination.value.address_prefix_type
      address_prefix      = destination.value.address_prefix
    }
  }
}

####################################################
# deployment
####################################################

# connectivity

resource "azurerm_network_manager_deployment" "conn_config_hub_spoke_region2" {
  network_manager_id = azurerm_network_manager.avnm.id
  location           = local.region2
  scope_access       = "Connectivity"
  configuration_ids = [
    azurerm_network_manager_connectivity_configuration.conn_config_hub_spoke_region2.id,
    azurerm_network_manager_connectivity_configuration.conn_config_mesh_float.id,
  ]
  triggers = {
    connectivity_configuration_id = azurerm_network_manager_connectivity_configuration.conn_config_hub_spoke_region2.id
    policy_json_region2           = local.policy_ng_spokes_prod_region2
    policy_json_global            = local.policy_ng_spokes_prod_float
  }
}

resource "azurerm_network_manager_deployment" "secadmin_config_region2" {
  network_manager_id = azurerm_network_manager.avnm.id
  location           = local.region2
  scope_access       = "SecurityAdmin"
  configuration_ids = [
    azurerm_network_manager_security_admin_configuration.secadmin_config_region2.id,
  ]
  triggers = {
    connectivity_configuration_id = azurerm_network_manager_security_admin_configuration.secadmin_config_region2.id
    policy_json                   = local.policy_ng_spokes_prod_region2
    admin_rule_changes = jsonencode({
      protocol                = [for rule in local.secadmin_rules_global : rule.protocol]
      destination_port_ranges = [for rule in local.secadmin_rules_global : rule.destination_port_ranges]
    })
  }
  depends_on = [
    azurerm_network_manager_deployment.conn_config_hub_spoke_region2,
  ]
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
    azurerm_resource_group_policy_assignment.ng_spokes_prod_region2,
  ]
}

####################################################
# output files
####################################################

locals {
  avnm_files_region2 = {
    "output/policies/pol-ng-spokes-prod-region2.json" = local.policy_ng_spokes_prod_region2
  }
}

resource "local_file" "avnm_files_region2" {
  for_each = local.avnm_files_region2
  filename = each.key
  content  = each.value
}
