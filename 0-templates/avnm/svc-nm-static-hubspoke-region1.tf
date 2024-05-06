
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
        module.spoke1.vnet.id,
        module.spoke2.vnet.id,
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
    configuration_ids   = [module.nm_mesh_global.connectivity_configurations["cc-ng-mesh-global"].id, ]
  }

  security_deployment = {
    configuration_names = ["sac-ng-hubspoke-region1"]
    configuration_ids   = []
  }
}
