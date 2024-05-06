
locals {
  policy_ng_vnets_global = templatefile("../../policies/avnm/ng-vnets-global.json", {
    NETWORK_GROUP_ID = module.nm_mesh_global.vnet_network_groups["ng-mesh-global"].id
    LAB_ID           = local.prefix
    ENV              = "prod"
    NODE_TYPE        = "float"
  })
}

####################################################
# network manager
####################################################

# instance

resource "azurerm_network_manager" "avnm" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.region1
  name                = "${local.prefix}-avnm"
  description         = "global"
  scope_accesses = [
    "Connectivity",
    "SecurityAdmin"
  ]
  scope {
    subscription_ids = [
      data.azurerm_subscription.current.id,
    ]
  }
}

####################################################
# deployments
####################################################

# global

module "nm_mesh_global" {
  source             = "../../modules/network-manager"
  resource_group     = azurerm_resource_group.rg.name
  prefix             = local.prefix
  network_manager_id = azurerm_network_manager.avnm.id

  network_groups = [
    {
      name        = "ng-mesh-global"
      description = "All floating spokes in prod"
      member_type = "VirtualNetwork"
      static_members = [
        # module.spoke3.vnet.id,
      ]
    },
  ]

  connectivity_configurations = [
    {
      name                  = "cc-ng-mesh-global"
      network_group_name    = "ng-mesh-global"
      connectivity_topology = "Mesh"
      global_mesh_enabled   = true
      applies_to_group = {
        group_connectivity  = "DirectlyConnected"
        global_mesh_enabled = true
      }
    },
  ]
}


####################################################
# policy definitions
####################################################

resource "azurerm_policy_definition" "ng_mesh_global" {
  name         = "${local.prefix}-ng-mesh-global"
  policy_type  = "Custom"
  mode         = "Microsoft.Network.Data"
  display_name = "All spokes in prod"
  metadata     = templatefile("../../policies/avnm/metadata.json", {})
  policy_rule  = local.policy_ng_vnets_global
}

####################################################
# policy assignments
####################################################

# float

resource "azurerm_resource_group_policy_assignment" "ng_mesh_global" {
  name                 = "${local.prefix}-ng-mesh-global"
  policy_definition_id = azurerm_policy_definition.ng_mesh_global.id
  resource_group_id    = azurerm_resource_group.rg.id
}

####################################################
# output files
####################################################

locals {
  avnm_files_global = {
    "output/policies/azpol-ng-vnets-global.json" = local.policy_ng_vnets_global
  }
}

resource "local_file" "avnm_files_global" {
  for_each = local.avnm_files_global
  filename = each.key
  content  = each.value
}
