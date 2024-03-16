
locals {
  policy_ng_spokes_prod_region1 = templatefile("../../policies/avnm/ng-spokes-prod-region.json", {
    NETWORK_GROUP_ID = azurerm_network_manager_network_group.ng_spokes_prod_region1.id
    LOCATION         = local.region1
    LAB_ID           = local.prefix
  })
  policy_cleanup_commands_region1 = [
    "az policy assignment delete -n ${local.prefix}-ng-spokes-prod-region1",
    "az policy definition delete -n ${local.prefix}-ng-spokes-prod-region1",
  ]
}

####################################################
# network groups
####################################################

resource "azurerm_network_manager_network_group" "ng_spokes_prod_region1" {
  name               = "${local.prefix}-ng-spokes-prod-region1"
  network_manager_id = azurerm_network_manager.avnm.id
}

####################################################
# policy definitions
####################################################

resource "azurerm_policy_definition" "ng_spokes_prod_region1" {
  name         = "${local.prefix}-ng-spokes-prod-region1"
  policy_type  = "Custom"
  mode         = "Microsoft.Network.Data"
  display_name = "All spokes in prod region1"
  metadata     = templatefile("../../policies/avnm/metadata.json", {})
  policy_rule  = local.policy_ng_spokes_prod_region1
}

####################################################
# policy assignments
####################################################

resource "azurerm_resource_group_policy_assignment" "ng_spokes_prod_region1" {
  name                 = "${local.prefix}-ng-spokes-prod-region1"
  policy_definition_id = azurerm_policy_definition.ng_spokes_prod_region1.id
  resource_group_id    = azurerm_resource_group.rg.id
}

####################################################
# configuration
####################################################

# connectivity
#---------------------------

resource "azurerm_network_manager_connectivity_configuration" "conn_config_hub_spoke_region1" {
  name                  = "${local.prefix}-conn-config-hub-spoke-region1"
  network_manager_id    = azurerm_network_manager.avnm.id
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
# security
####################################################

resource "azurerm_network_manager_security_admin_configuration" "secadmin_config_region1" {
  name               = "${local.prefix}-secadmin-config-region1"
  network_manager_id = azurerm_network_manager.avnm.id
}

resource "azurerm_network_manager_admin_rule_collection" "secadmin_rule_col_region1" {
  name                            = "${local.prefix}-secadmin-rule-col-region1"
  security_admin_configuration_id = azurerm_network_manager_security_admin_configuration.secadmin_config_region1.id
  network_group_ids = [
    azurerm_network_manager_network_group.ng_spokes_prod_region1.id
  ]
}

locals {
  secadmin_rules_region1 = [
    {
      description             = "rdp"
      action                  = "Allow"
      direction               = "Inbound"
      priority                = 1
      protocol                = "Tcp"
      destination_port_ranges = ["3333"]
      source = [
        { address_prefix_type = "IPPrefix", address_prefix = "*" }
      ]
      destinations = [
        { address_prefix_type = "IPPrefix", address_prefix = "*" }
      ]
    }
  ]
}

resource "azurerm_network_manager_admin_rule" "secadmin_rules_region1" {
  for_each                 = { for r in local.secadmin_rules_region1 : r.description => r }
  name                     = "${local.prefix}-secadmin-rules-region1"
  admin_rule_collection_id = azurerm_network_manager_admin_rule_collection.secadmin_rule_col_region1.id
  description              = each.value.description
  action                   = each.value.action
  direction                = each.value.direction
  priority                 = each.value.priority
  protocol                 = each.value.protocol
  source_port_ranges       = try(each.value.source_port_ranges, null)
  destination_port_ranges  = each.value.destination_port_ranges

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

resource "azurerm_network_manager_deployment" "conn_config_hub_spoke_region1" {
  network_manager_id = azurerm_network_manager.avnm.id
  location           = local.region1
  scope_access       = "Connectivity"
  configuration_ids = [
    azurerm_network_manager_connectivity_configuration.conn_config_hub_spoke_region1.id,
  ]
  triggers = {
    connectivity_configuration_id = azurerm_network_manager_connectivity_configuration.conn_config_hub_spoke_region1.id
    policy_json                   = local.policy_ng_spokes_prod_region1
  }
}

resource "azurerm_network_manager_deployment" "secadmin_config_region1" {
  network_manager_id = azurerm_network_manager.avnm.id
  location           = local.region1
  scope_access       = "SecurityAdmin"
  configuration_ids = [
    azurerm_network_manager_security_admin_configuration.secadmin_config_region1.id,
  ]
  triggers = {
    connectivity_configuration_id = azurerm_network_manager_security_admin_configuration.secadmin_config_region1.id
    policy_json                   = local.policy_ng_spokes_prod_region1
  }
  depends_on = [
    azurerm_network_manager_deployment.conn_config_hub_spoke_region1
  ]
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
    azurerm_resource_group_policy_assignment.ng_spokes_prod_region1,
  ]
}

####################################################
# output files
####################################################

locals {
  avnm_files_region1 = {
    "output/policies/pol-ng-spokes.json" = local.policy_ng_spokes_prod_region1
  }
}

resource "local_file" "avnm_files_region1" {
  for_each = local.avnm_files_region1
  filename = each.key
  content  = each.value
}
