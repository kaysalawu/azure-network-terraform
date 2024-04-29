
####################################################
# vnets
####################################################

# mesh1
#-----------------------------

# vnet

module "mesh1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = "${local.prefix}-mesh1"
  location        = local.region1
  storage_account = module.common.storage_accounts["region1"]
  tags            = { "lab" = local.prefix, "env" = "prod", "nodeType" = "mesh", "udrType" = "private" }

  nsg_subnet_map = {
    "MainSubnet" = module.common.nsg_main["region1"].id
    "TestSubnet" = module.common.nsg_main["region1"].id
  }

  config_vnet = {
    address_space = ["10.51.0.0/20", "10.91.0.0/20", "fd00:db8:51::/56", "fd00:db8:91::/56", ]
    subnets = {
      ("MainSubnet") = { address_prefixes = ["10.51.0.0/24", "fd00:db8:51::/64", ] }
      ("TestSubnet") = { address_prefixes = ["10.91.0.0/24", "fd00:db8:91::/64", ] }
    }
    nat_gateway_subnet_names = [
      "MainSubnet",
      "TestSubnet",
    ]
  }
  depends_on = [
    module.common,
  ]
}

# workload

module "mesh1_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-Mesh1Vm"
  computer_name   = "Mesh1Vm"
  location        = local.region1
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.vm_cloud_init.cloud_config)

  enable_ipv6 = local.enable_ipv6
  interfaces = [
    {
      name      = "${local.prefix}-Mesh1Vm-main-nic"
      subnet_id = module.mesh1.subnets["MainSubnet"].id
    },
    {
      name      = "${local.prefix}-Mesh1Vm-aks-nic"
      subnet_id = module.mesh1.subnets["TestSubnet"].id
    },
  ]
  depends_on = [
    module.hub1,
  ]
}

# mesh2
#-----------------------------

# vnet

module "mesh2" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = "${local.prefix}-mesh2"
  location        = local.region1
  storage_account = module.common.storage_accounts["region1"]
  tags            = { "lab" = local.prefix, "env" = "prod", "nodeType" = "mesh", "udrType" = "private" }

  nsg_subnet_map = {
    "MainSubnet" = module.common.nsg_main["region1"].id
    "TestSubnet" = module.common.nsg_main["region1"].id
  }

  config_vnet = {
    address_space = ["10.52.0.0/20", "10.92.0.0/20", "fd00:db8:52::/56", "fd00:db8:92::/56", ]
    subnets = {
      ("MainSubnet") = { address_prefixes = ["10.52.0.0/24", "fd00:db8:52::/64", ] }
      ("TestSubnet") = { address_prefixes = ["10.92.0.0/24", "fd00:db8:92::/64", ] }
    }
    nat_gateway_subnet_names = [
      "MainSubnet",
      "TestSubnet",
    ]
  }
  depends_on = [module.common, ]
}

# workload

module "mesh2_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-Mesh2Vm"
  computer_name   = "Mesh2Vm"
  location        = local.region1
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.vm_cloud_init.cloud_config)

  enable_ipv6 = local.enable_ipv6
  interfaces = [
    {
      name      = "${local.prefix}-Mesh2Vm-main-nic"
      subnet_id = module.mesh2.subnets["MainSubnet"].id
    },
    {
      name      = "${local.prefix}-Mesh2Vm-aks-nic"
      subnet_id = module.mesh2.subnets["TestSubnet"].id
    },
  ]
  depends_on = [
    module.hub1,
  ]
}

# mesh3
# (TestSubnet reused)
#-----------------------------

module "mesh3" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = "${local.prefix}-mesh3"
  location        = local.region1
  storage_account = module.common.storage_accounts["region1"]
  tags            = { "lab" = local.prefix, "env" = "prod", "nodeType" = "mesh", "udrType" = "None" }

  nsg_subnet_map = {
    "MainSubnet" = module.common.nsg_main["region1"].id
    "TestSubnet" = module.common.nsg_main["region1"].id
  }

  config_vnet = {
    address_space = ["10.53.0.0/20", "10.90.0.0/20", "fd00:db8:53::/56", "fd00:db8:93::/56", ]
    subnets = {
      ("MainSubnet") = { address_prefixes = ["10.53.0.0/24", "fd00:db8:53::/64", ] }
      ("TestSubnet") = { address_prefixes = ["10.90.0.0/24", "fd00:db8:93::/64", ] }
    }
    nat_gateway_subnet_names = [
      "MainSubnet",
      "TestSubnet",
    ]
  }
  depends_on = [module.common, ]
}

# workload

module "mesh3_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-Mesh3Vm"
  computer_name   = "Mesh3Vm"
  location        = local.region1
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.vm_cloud_init.cloud_config)

  enable_ipv6 = local.enable_ipv6
  interfaces = [
    {
      name      = "${local.prefix}-Mesh3Vm-main-nic"
      subnet_id = module.mesh3.subnets["MainSubnet"].id
    },
    {
      name      = "${local.prefix}-Mesh3Vm-aks-nic"
      subnet_id = module.mesh3.subnets["TestSubnet"].id
    },
  ]
}

# mesh4
# (TestSubnet reused)
#-----------------------------

module "mesh4" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = "${local.prefix}-mesh4"
  location        = local.region1
  storage_account = module.common.storage_accounts["region1"]
  tags            = { "lab" = local.prefix, "env" = "prod", "nodeType" = "mesh", "udrType" = "None" }

  nsg_subnet_map = {
    "MainSubnet" = module.common.nsg_main["region1"].id
    "TestSubnet" = module.common.nsg_main["region1"].id
  }

  config_vnet = {
    address_space = ["10.54.0.0/20", "10.90.0.0/20", "fd00:db8:54::/56", "fd00:db8:94::/56", ]
    subnets = {
      ("MainSubnet") = { address_prefixes = ["10.54.0.0/24", "fd00:db8:54::/64", ] }
      ("TestSubnet") = { address_prefixes = ["10.90.0.0/24", "fd00:db8:94::/64", ] }
    }
    nat_gateway_subnet_names = [
      "MainSubnet",
      "TestSubnet",
    ]
  }
  depends_on = [module.common, ]
}

# workload

module "mesh4_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-Mesh4Vm"
  computer_name   = "Mesh4Vm"
  location        = local.region1
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.vm_cloud_init.cloud_config)

  enable_ipv6 = local.enable_ipv6
  interfaces = [
    {
      name      = "${local.prefix}-Mesh4Vm-main-nic"
      subnet_id = module.mesh4.subnets["MainSubnet"].id
    },
    {
      name      = "${local.prefix}-Mesh4Vm-aks-nic"
      subnet_id = module.mesh4.subnets["TestSubnet"].id
    },
  ]
}

####################################################
# network groups
####################################################

# trusted-mesh region1

resource "azapi_resource" "ng_trusted_mesh_region1" {
  count     = local.use_azapi ? 1 : 0
  type      = "Microsoft.Network/networkManagers/networkGroups@2022-06-01-preview"
  name      = "ng-trusted-mesh-region1"
  parent_id = local.network_manager.id

  body = jsonencode({
    properties = {
      description = "Subnets that are meshed in trusted group, and need NVA for east-west and north-south traffic"
      memberType  = "Subnet"
    }
  })
  schema_validation_enabled = false
}

# untrusted-mesh region1

resource "azapi_resource" "ng_isolated_mesh_region1" {
  count     = local.use_azapi ? 1 : 0
  type      = "Microsoft.Network/networkManagers/networkGroups@2022-06-01-preview"
  name      = "ng-isolated-mesh-region1"
  parent_id = local.network_manager.id

  body = jsonencode({
    properties = {
      description = "Subnets that are meshed in an isolated group, and do not need NVA for east-west and north-south traffic"
      memberType  = "Subnet"
    }
  })
  schema_validation_enabled = false
}

####################################################
# membership
####################################################

locals {
  ng_trusted_mesh_region1 = [
    module.mesh1.subnets["MainSubnet"].id,
    module.mesh2.subnets["MainSubnet"].id,
  ]
  ng_isolated_mesh_region1 = [
    module.mesh3.subnets["MainSubnet"].id,
    module.mesh4.subnets["MainSubnet"].id,
  ]
}

resource "azapi_resource" "static_members_trusted_mesh_region1" {
  type      = "Microsoft.Network/networkManagers/networkGroups/staticMembers@2022-11-01"
  count     = length(local.ng_trusted_mesh_region1)
  name      = "ng-trusted-mesh-region1-${count.index}"
  parent_id = azapi_resource.ng_trusted_mesh_region1.0.id

  body = jsonencode({
    properties = {
      resourceId = local.ng_trusted_mesh_region1[count.index]
    }
  })
  schema_validation_enabled = false
}

resource "azapi_resource" "static_members_isolated_mesh_region1" {
  type      = "Microsoft.Network/networkManagers/networkGroups/staticMembers@2022-11-01"
  count     = length(local.ng_isolated_mesh_region1)
  name      = "ng-untrusted-mesh-region1-${count.index}"
  parent_id = azapi_resource.ng_isolated_mesh_region1.0.id

  body = jsonencode({
    properties = {
      resourceId = local.ng_isolated_mesh_region1[count.index]
    }
  })
  schema_validation_enabled = false
}

####################################################
# configuration
####################################################

locals {
  routing_config_hubspoke_rule_col_rules = [
    {
      name             = "default-ipv4"
      type             = "AddressPrefix"
      address_prefix   = "0.0.0.0/0"
      next_hop_type    = "VirtualAppliance"
      next_hop_address = module.hub1.firewall_private_ip
    },
  ]
}

# hubspoke-region1
#-----------------------------

resource "azapi_resource" "routing_config_hubspoke" {
  type      = "Microsoft.Network/networkManagers/routingConfigurations@2022-06-01-preview"
  name      = "routing-config-hubspoke"
  parent_id = local.network_manager.id

  body = jsonencode({
    properties = {
      description = "Routing configuration for hub-spoke topology"
    }
  })
  schema_validation_enabled = false
}

resource "azapi_resource" "routing_config_hubspoke_rule_col" {
  type      = "Microsoft.Network/networkManagers/routingConfigurations/ruleCollections@2022-06-01-preview"
  name      = "rule-col-hubspoke-region1"
  parent_id = azapi_resource.routing_config_hubspoke.id

  body = jsonencode({
    properties = {
      description       = "region1"
      localRouteSetting = "DirectRoutingWithinVNet"
      appliesTo = [
        {
          networkGroupId = azurerm_network_manager_network_group.ng_spokes_prod_region1.id
        }
      ]
      disableBgpRoutePropagation = "True"
    }
  })
  schema_validation_enabled = false
}

resource "azapi_resource" "routing_config_hubspoke_rule_col_rules" {
  for_each  = { for r in local.routing_config_hubspoke_rule_col_rules : r.name => r }
  type      = "Microsoft.Network/networkManagers/routingConfigurations/ruleCollections/rules@2022-06-01-preview"
  name      = each.value.name
  parent_id = azapi_resource.routing_config_hubspoke_rule_col.id

  body = jsonencode({
    properties = {
      destination : {
        type               = each.value.type
        destinationAddress = each.value.address_prefix
      },
      nextHop : {
        nextHopType    = each.value.next_hop_type
        nextHopAddress = each.value.next_hop_address
      }
    }
  })
  schema_validation_enabled = false
}

####################################################
# deployment
####################################################

# hubspoke-region1
#-----------------------------

# resource "azapi_resource" "routing_config_hubspoke" {
#   type      = "Microsoft.Network/networkManagers/routingConfigurations@2022-06-01-preview"
#   name      = "routing-config-hubspoke"
#   parent_id = local.network_manager.id

#   body = jsonencode({
#     properties = {
#       description = "Routing configuration for hub-spoke topology"
#     }
#   })
#   schema_validation_enabled = false
# }
