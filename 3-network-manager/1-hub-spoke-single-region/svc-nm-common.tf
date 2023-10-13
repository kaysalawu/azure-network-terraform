
####################################################
# network manager
####################################################

resource "azurerm_network_manager" "network_manager_instance" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "${local.prefix}-nm"
  scope_accesses      = ["Connectivity", "SecurityAdmin"]
  description         = "regional hub and spoke"
  scope {
    subscription_ids = [data.azurerm_subscription.current.id]
  }
}

####################################################
# network groups
####################################################

# spokes
#---------------------------

# region1

locals {
  policy_ng_prod_region1 = templatefile("../../policies/avnm/ng-hub-spoke-prod.json", {
    NETWORK_GROUP_ID = azurerm_network_manager_network_group.ng_spokes_prod_region1.id
    LOCATION         = local.region1
  })
  policy_ng_spokes_prod_region1 = templatefile("../../policies/avnm/ng-spokes-prod.json", {
    NETWORK_GROUP_ID = azurerm_network_manager_network_group.ng_spokes_prod_region1.id
    LOCATION         = local.region1
  })
}

resource "azurerm_network_manager_network_group" "ng_spokes_prod_region1" {
  name               = "${local.prefix}-ng-spokes-prod-region1"
  network_manager_id = azurerm_network_manager.network_manager_instance.id
}

resource "azurerm_policy_definition" "ng_spokes_prod_region1" {
  name         = "${local.prefix}-ng-spokes-prod-region1"
  policy_type  = "Custom"
  mode         = "Microsoft.Network.Data"
  display_name = "Policy Definition for Network Group"

  metadata = <<METADATA
    {
      "category": "Azure Virtual Network Manager"
    }
  METADATA

  policy_rule = local.policy_ng_spokes_prod_region1
}

resource "azurerm_subscription_policy_assignment" "ng_spokes_prod_region1" {
  name                 = "${local.prefix}-ng-spokes-prod-region1"
  policy_definition_id = azurerm_policy_definition.ng_spokes_prod_region1.id
  subscription_id      = data.azurerm_subscription.current.id
}

####################################################
# output files
####################################################

locals {
  avnm_files = {
    "output/policies/pol-ng-region1.json"        = local.policy_ng_prod_region1
    "output/policies/pol-ng-spokes-region1.json" = local.policy_ng_spokes_prod_region1
  }
}

resource "local_file" "avnm_files" {
  for_each = local.avnm_files
  filename = each.key
  content  = each.value
}
