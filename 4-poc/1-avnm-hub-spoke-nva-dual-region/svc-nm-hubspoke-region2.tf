
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
# vnet static members
####################################################

locals {
  ng_spokes_prod_region2_static_members = {
    "spoke4" = module.spoke4.vnet.id
    "spoke5" = module.spoke5.vnet.id
  }
}

resource "azurerm_network_manager_static_member" "ng_spokes_prod_region2" {
  for_each                  = local.ng_spokes_prod_region2_static_members
  name                      = "${local.prefix}-ng-spokes-prod-region2-${each.key}"
  network_group_id          = azurerm_network_manager_network_group.ng_spokes_prod_region2.id
  target_virtual_network_id = each.value
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
    module.hub2,
    azurerm_network_manager_static_member.ng_spokes_prod_region2,
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
  depends_on = [
    azurerm_network_manager_static_member.ng_spokes_prod_region2,
  ]
}

####################################################
# output files
####################################################

locals {
  netman_files_region2 = {}
}

resource "local_file" "netman_files_region2" {
  for_each = local.netman_files_region2
  filename = each.key
  content  = each.value
}
