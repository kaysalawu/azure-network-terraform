
locals {
  policy_ng_spokes_prod_float = templatefile("../../policies/avnm/ng-spokes-prod-float.json", {
    NETWORK_GROUP_ID = azurerm_network_manager_network_group.ng_spokes_prod_float.id
    LAB_ID           = local.prefix
    ENV              = "prod"
    NODE_TYPE        = "float"
  })
  secadmin_rules_global = {
    "tcp-high-risk" = {
      description = "tcp-high-risk"
      action      = "Deny"
      direction   = "Inbound"
      priority    = 1
      protocol    = "Tcp"
      destination_port_ranges = [
        "20",
        "21",
        "23",
        "111",
        "119",
        "135",
        "161",
        "162",
        "445",
        "512",
        "514",
        "593",
        "873",
        "2049",
        "5800",
        "5900",
        "11211"
      ]
      source = [
        { address_prefix_type = "IPPrefix", address_prefix = "*" }
      ]
      destinations = [
        { address_prefix_type = "IPPrefix", address_prefix = "*" }
      ]
    },
    "udp-high-risk" = {
      description = "udp-high-risk"
      action      = "Deny"
      direction   = "Inbound"
      priority    = 2
      protocol    = "Udp"
      destination_port_ranges = [
        "111",
        "135",
        "162",
        "593",
        "2049",
      ]
      source = [
        { address_prefix_type = "IPPrefix", address_prefix = "*" }
      ]
      destinations = [
        { address_prefix_type = "IPPrefix", address_prefix = "*" }
      ]
    }
  }
}

####################################################
# network manager
####################################################

resource "azurerm_network_manager" "avnm" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.region1
  name                = "${local.prefix}-avnm"
  scope_accesses      = ["Connectivity", "SecurityAdmin"]
  description         = "global"
  scope {
    subscription_ids = [
      data.azurerm_subscription.current.id,
    ]
  }
}

####################################################
# network groups
####################################################

resource "azurerm_network_manager_network_group" "ng_spokes_prod_float" {
  name               = "${local.prefix}-ng-spokes-prod-float"
  network_manager_id = azurerm_network_manager.avnm.id
}

####################################################
# policy definitions
####################################################

resource "azurerm_policy_definition" "ng_spokes_prod_float" {
  name         = "${local.prefix}-ng-spokes-prod-float"
  policy_type  = "Custom"
  mode         = "Microsoft.Network.Data"
  display_name = "All spokes in prod"
  metadata     = templatefile("../../policies/avnm/metadata.json", {})
  policy_rule  = local.policy_ng_spokes_prod_float
}

####################################################
# configuration
####################################################

# connectivity
#---------------------------

resource "azurerm_network_manager_connectivity_configuration" "conn_config_mesh_float" {
  name                  = "${local.prefix}-conn-config-mesh-float"
  network_manager_id    = azurerm_network_manager.avnm.id
  connectivity_topology = "Mesh"

  applies_to_group {
    group_connectivity  = "DirectlyConnected"
    network_group_id    = azurerm_network_manager_network_group.ng_spokes_prod_float.id
    global_mesh_enabled = true
    use_hub_gateway     = false
  }
  depends_on = [
    module.hub1
  ]
}

/*
####################################################
# security
####################################################

# resource "azurerm_network_manager_security_admin_configuration" "secadmin_config_region1" {
#   name               = "${local.prefix}-secadmin-config-region1"
#   network_manager_id = azurerm_network_manager.avnm.id
# }

# resource "azurerm_network_manager_admin_rule_collection" "secadmin_rule_col_region1" {
#   name                            = "${local.prefix}-secadmin-rule-col-region1"
#   security_admin_configuration_id = azurerm_network_manager_security_admin_configuration.secadmin_config_region1.id
#   network_group_ids = [
#     azurerm_network_manager_network_group.ng_spokes_prod_region1.id
#   ]
# }
*/
