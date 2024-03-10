
####################################################
# network groups
####################################################

resource "azurerm_network_manager_network_group" "ng_spokes_prod_region2" {
  name               = "${local.prefix}-ng-spokes-prod-region2"
  network_manager_id = azurerm_network_manager.avnm.id
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

locals {
  secadmin_rules_region2 = [
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

resource "azurerm_network_manager_admin_rule" "secadmin_rules_region2" {
  for_each                 = { for r in local.secadmin_rules_region2 : r.description => r }
  name                     = "${local.prefix}-secadmin-rules-region2"
  admin_rule_collection_id = azurerm_network_manager_admin_rule_collection.secadmin_rule_col_region2.id
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
# membership
####################################################

locals {
  members_region2 = [
    module.spoke4.vnet.id,
    module.spoke5.vnet.id
  ]
}

resource "azurerm_network_manager_static_member" "members_region2" {
  count                     = length(local.members_region2)
  name                      = "${local.prefix}-members-region2-${count.index}"
  network_group_id          = azurerm_network_manager_network_group.ng_spokes_prod_region2.id
  target_virtual_network_id = local.members_region2[count.index]
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
    azurerm_network_manager_connectivity_configuration.conn_config_hub_spoke_region2.id
  ]
  triggers = {
    connectivity_configuration_ids = azurerm_network_manager_connectivity_configuration.conn_config_hub_spoke_region2.id
  }
  depends_on = [
    azurerm_network_manager_network_group.ng_spokes_prod_region2,
    azurerm_network_manager_static_member.members_region2,
  ]
}

resource "azurerm_network_manager_deployment" "secadmin_config_region2" {
  network_manager_id = azurerm_network_manager.avnm.id
  location           = local.region2
  scope_access       = "SecurityAdmin"
  configuration_ids = [
    azurerm_network_manager_security_admin_configuration.secadmin_config_region2.id,
  ]
  triggers = {
    connectivity_configuration_ids = azurerm_network_manager_security_admin_configuration.secadmin_config_region2.id
  }
  depends_on = [
    azurerm_network_manager_deployment.conn_config_hub_spoke_region2,
    azurerm_network_manager_network_group.ng_spokes_prod_region2,
    azurerm_network_manager_static_member.members_region2,
  ]
}

####################################################
# output files
####################################################

locals {
  avnm_files_region2 = {}
}

resource "local_file" "avnm_files_region2" {
  for_each = local.avnm_files_region2
  filename = each.key
  content  = each.value
}
