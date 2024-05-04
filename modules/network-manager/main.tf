
locals {
  prefix = var.prefix == "" ? "" : format("%s-", var.prefix)
}

####################################################
# network group
####################################################

# vnet

resource "azapi_resource" "network_group_vnet" {
  count     = var.use_azapi ? 1 : 0
  type      = "Microsoft.Network/networkManagers/networkGroups@2022-06-01-preview"
  name      = "ng-trusted-mesh-networks-region1"
  parent_id = local.network_manager.id

  body = jsonencode({
    properties = {
      description = "network group for hub and spoke (meshed) topology"
      memberType  = "VirtualNetwork"
    }
  })
  schema_validation_enabled = false
}


