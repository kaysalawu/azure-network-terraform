
locals {
  policy_ng_vnets_region1 = templatefile("../../policies/avnm/ng-vnets-region.json", {
    NETWORK_GROUP_ID = module.nm_region1.vnet_network_groups["ng-hubspoke-region1"].id
    LOCATION         = local.region1
    LAB_ID           = local.prefix
    ENV              = "prod"
    NODE_TYPE        = "spoke"
  })
}

####################################################
# deployments
####################################################

# region1

module "nm_region1" {
  source             = "../../modules/network-manager"
  resource_group     = azurerm_resource_group.rg.name
  prefix             = local.prefix
  location           = local.region1
  network_manager_id = azurerm_network_manager.avnm.id

  network_groups = [
    {
      name        = "ng-hubspoke-region1"
      description = "All spokes in prod region1"
      member_type = "VirtualNetwork"
      static_members = [
        # module.spoke1.vnet.id,
        # module.spoke2.vnet.id,
      ]
    },
  ]

  connectivity_configurations = [
    {
      deploy                = true
      name                  = "cc-ng-hubspoke-region1"
      network_group_name    = "ng-hubspoke-region1"
      connectivity_topology = "HubAndSpoke"
      global_mesh_enabled   = false
      applies_to_group = {
        group_connectivity  = "None"
        global_mesh_enabled = false
        use_hub_gateway     = true
      }
      hub = {
        resource_id   = module.hub1.vnet.id
        resource_type = "Microsoft.Network/virtualNetworks"
      }
    },
  ]

  security_admin_configurations = [
    {
      deploy           = true
      name             = "sac-ng-hubspoke-region1"
      rule_collections = []
    },
    {
      name             = "sac2-ng-hubspoke-region1"
      rule_collections = []
    },
  ]

  connectivity_deployment = {
    configuration_names = ["cc-ng-hubspoke-region1", ]
    # configuration_ids   = [module.nm_mesh_global.connectivity_configurations["cc-ng-mesh-global"].id, ]
  }

  security_deployment = {
    configuration_names = ["sac-ng-hubspoke-region1"]
    configuration_ids   = []
  }

  depends_on = [
    module.hub1,
    module.spoke1,
    module.spoke2,
  ]
}

####################################################
# policy definitions
####################################################

resource "azurerm_policy_definition" "ng_hubspoke_region1" {
  name         = "${local.prefix}-ng-hubspoke-region1"
  policy_type  = "Custom"
  mode         = "Microsoft.Network.Data"
  display_name = "All spokes in prod region1"
  metadata     = templatefile("../../policies/avnm/metadata.json", {})
  policy_rule  = local.policy_ng_vnets_region1
}

####################################################
# policy assignments
####################################################

resource "azurerm_resource_group_policy_assignment" "ng_hubspoke_region1" {
  name                 = "${local.prefix}-ng-hubspoke-region1"
  policy_definition_id = azurerm_policy_definition.ng_hubspoke_region1.id
  resource_group_id    = azurerm_resource_group.rg.id
}

####################################################
# output files
####################################################

locals {
  avnm_files_region1 = {
    "output/policies/pol-ng-vnets-region1.json" = local.policy_ng_vnets_region1
  }
}

resource "local_file" "avnm_files_region1" {
  for_each = local.avnm_files_region1
  filename = each.key
  content  = each.value
}
