
locals {
  nm_vm_script_targets_region1 = [
    { name = "branch1", dns = lower(local.branch1_vm_fqdn), ipv4 = local.branch1_vm_addr, ipv6 = local.branch1_vm_addr_v6, probe = true },
    { name = "hub1   ", dns = lower(local.hub1_vm_fqdn), ipv4 = local.hub1_vm_addr, ipv6 = local.hub1_vm_addr_v6, probe = false },
    { name = "hub1-spoke3-pep", dns = lower(local.hub1_spoke3_pep_fqdn), ping = false, probe = true },
    { name = "spoke1 ", dns = lower(local.spoke1_vm_fqdn), ipv4 = local.spoke1_vm_addr, ipv6 = local.spoke1_vm_addr_v6, probe = true },
    { name = "spoke2 ", dns = lower(local.spoke2_vm_fqdn), ipv4 = local.spoke2_vm_addr, ipv6 = local.spoke2_vm_addr_v6, probe = true },
    { name = "mesh1  ", dns = module.mesh1_vm.private_ip_address, ipv4 = module.mesh1_vm.private_ip_address, },
    { name = "mesh2  ", dns = module.mesh2_vm.private_ip_address, ipv4 = module.mesh2_vm.private_ip_address, },
    { name = "mesh1test", dns = module.mesh1_test_vm.private_ip_address, ipv4 = module.mesh1_test_vm.private_ip_address, },
    { name = "mesh2test", dns = module.mesh2_test_vm.private_ip_address, ipv4 = module.mesh2_test_vm.private_ip_address, },
  ]
  nm_vm_script_targets_misc = [
    { name = "internet", dns = "icanhazip.com", ipv4 = "icanhazip.com", ipv6 = "icanhazip.com" },
    { name = "hub1-spoke3-blob", dns = local.spoke3_blob_url, ping = false, probe = true },
  ]
  nm_vm_script_targets = concat(
    local.nm_vm_script_targets_region1,
    local.nm_vm_script_targets_misc,
  )
  nm_vm_init_vars = {
    TARGETS                   = local.nm_vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
  }
  nm_vm_init_files = {
    "${local.init_dir}/fastapi/docker-compose-app1-80.yml"   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/docker-compose-app1-80.yml", {}) }
    "${local.init_dir}/fastapi/docker-compose-app2-8080.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/docker-compose-app2-8080.yml", {}) }
    "${local.init_dir}/fastapi/app/app/Dockerfile"           = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/Dockerfile", {}) }
    "${local.init_dir}/fastapi/app/app/_app.py"              = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/_app.py", {}) }
    "${local.init_dir}/fastapi/app/app/main.py"              = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/main.py", {}) }
    "${local.init_dir}/fastapi/app/app/requirements.txt"     = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/requirements.txt", {}) }
  }
  nm_vm_startup_init_files = {
    "${local.init_dir}/init/startup.sh" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/startup.sh", local.nm_vm_init_vars) }
  }

  nm_region1_default_udr_destinations = [
    { name = "default-region1", address_prefix = ["0.0.0.0/0"], next_hop_ip = local.hub1_nva_ilb_trust_addr },
    { name = "defaultv6-region1", address_prefix = ["::/0"], next_hop_ip = local.hub1_nva_ilb_trust_addr_v6 }
  ]
  nm_spoke2_udr_main_routes = concat(local.region1_default_udr_destinations, [
    { name = "hub1", address_prefix = [local.hub1_address_space.0, ], next_hop_ip = local.hub1_nva_ilb_trust_addr },
    { name = "hub1v6", address_prefix = [local.hub1_address_space.2, ], next_hop_ip = local.hub1_nva_ilb_trust_addr_v6 },
  ])
  nm_hub1_udr_main_routes = concat(local.region1_default_udr_destinations, [
    { name = "spoke1", address_prefix = [local.spoke1_address_space.0, ], next_hop_ip = local.hub1_nva_ilb_trust_addr },
    { name = "spoke2", address_prefix = [local.spoke2_address_space.0, ], next_hop_ip = local.hub1_nva_ilb_trust_addr },
    { name = "spoke1v6", address_prefix = [local.spoke1_address_space.1, ], next_hop_ip = local.hub1_nva_ilb_trust_addr_v6 },
    { name = "spoke2v6", address_prefix = [local.spoke2_address_space.1, ], next_hop_ip = local.hub1_nva_ilb_trust_addr_v6 },
  ])
}

module "nm_vm_cloud_init" {
  source = "../../modules/cloud-config-gen"
  files = merge(
    local.nm_vm_init_files,
    local.nm_vm_startup_init_files
  )
  packages = [
    "docker.io", "docker-compose", #npm,
  ]
  run_commands = [
    "systemctl enable docker",
    "systemctl start docker",
    "bash ${local.init_dir}/init/startup.sh",
    "docker-compose -f ${local.init_dir}/fastapi/docker-compose-app1-80.yml up -d",
    "docker-compose -f ${local.init_dir}/fastapi/docker-compose-app2-8080.yml up -d",
  ]
}

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
  custom_data     = base64encode(module.nm_vm_cloud_init.cloud_config)

  enable_ipv6 = local.enable_ipv6
  interfaces = [
    {
      name      = "${local.prefix}-Mesh1Vm-main-nic"
      subnet_id = module.mesh1.subnets["MainSubnet"].id
    },
  ]
  depends_on = [
    module.hub1,
  ]
}

module "mesh1_test_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-Mesh1TestVm"
  computer_name   = "Mesh1TestVm"
  location        = local.region1
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.nm_vm_cloud_init.cloud_config)

  enable_ipv6 = local.enable_ipv6
  interfaces = [
    {
      name      = "${local.prefix}-Mesh1TestVm-main-nic"
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
      # "MainSubnet",
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
  custom_data     = base64encode(module.nm_vm_cloud_init.cloud_config)

  enable_ipv6 = local.enable_ipv6
  interfaces = [
    {
      name      = "${local.prefix}-Mesh2Vm-main-nic"
      subnet_id = module.mesh2.subnets["MainSubnet"].id
    },
  ]
  depends_on = [
    module.hub1,
  ]
}

module "mesh2_test_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-Mesh2TestVm"
  computer_name   = "Mesh2TestVm"
  location        = local.region1
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.nm_vm_cloud_init.cloud_config)

  enable_ipv6 = local.enable_ipv6
  interfaces = [
    {
      name      = "${local.prefix}-Mesh2TestVm-test-nic"
      subnet_id = module.mesh2.subnets["TestSubnet"].id
    },
  ]
  depends_on = [
    module.hub1,
  ]
}

####################################################
# vwan
####################################################

# vnet connections

locals {
  vhub1_mesh1_vnet_conn_routes = []
  vhub1_mesh2_vnet_conn_routes = []
}

# mesh1

resource "azurerm_virtual_hub_connection" "mesh1_vnet_conn" {
  name                      = "${local.vhub1_prefix}mesh1-vnet-conn"
  virtual_hub_id            = module.vhub1.virtual_hub.id
  remote_virtual_network_id = module.mesh1.vnet.id
  internet_security_enabled = false

  routing {
    associated_route_table_id = data.azurerm_virtual_hub_route_table.vhub1_default.id
    dynamic "static_vnet_route" {
      for_each = local.vhub1_mesh1_vnet_conn_routes
      content {
        name                = static_vnet_route.value.name
        address_prefixes    = static_vnet_route.value.address_prefixes
        next_hop_ip_address = static_vnet_route.value.next_hop_ip_address
      }
    }
  }
}

# mesh2

resource "azurerm_virtual_hub_connection" "mesh2_vnet_conn" {
  name                      = "${local.vhub1_prefix}mesh2-vnet-conn"
  virtual_hub_id            = module.vhub1.virtual_hub.id
  remote_virtual_network_id = module.mesh2.vnet.id
  internet_security_enabled = false

  routing {
    associated_route_table_id = data.azurerm_virtual_hub_route_table.vhub1_default.id
    dynamic "static_vnet_route" {
      for_each = local.vhub1_mesh2_vnet_conn_routes
      content {
        name                = static_vnet_route.value.name
        address_prefixes    = static_vnet_route.value.address_prefixes
        next_hop_ip_address = static_vnet_route.value.next_hop_ip_address
      }
    }
  }
}

####################################################
# network manager
####################################################

# module "network_manager" {
#   source                       = "../../modules/network-manager"
#   resource_group_name          = azurerm_resource_group.rg.name
#   prefix                       = local.prefix
#   location                     = local.region1
#   tags                         = local.tags
#   enable_diagnostics           = local.enable_diagnostics
#   log_analytics_workspace_name = local.log_analytics_workspace_name
# }

####################################################
# network groups
####################################################

# hub and spoke

resource "azapi_resource" "ng_trusted_mesh_networks_region1" {
  count     = local.use_azapi ? 1 : 0
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

# routing

resource "azapi_resource" "ng_hubspoke_mesh_subnets_region1" {
  count     = local.use_azapi ? 1 : 0
  type      = "Microsoft.Network/networkManagers/networkGroups@2022-06-01-preview"
  name      = "ng-hubspoke-mesh-subnets-region1"
  parent_id = local.network_manager.id

  body = jsonencode({
    properties = {
      description = "Subnets for meshed vnets in trusted group, and need NVA for east-west and north-south traffic"
      memberType  = "Subnet"
    }
  })
  schema_validation_enabled = false
}

####################################################
# membership
####################################################

locals {
  members_ng_trusted_mesh_networks_region1 = [
    module.mesh1.vnet.id,
    module.mesh2.vnet.id,
  ]
  members_ng_hubspoke_mesh_subnets_region1 = [
    module.mesh1.subnets["MainSubnet"].id,
    module.mesh2.subnets["MainSubnet"].id,
  ]
}

# networks

resource "azapi_resource" "members_ng_trusted_mesh_networks_region1" {
  type      = "Microsoft.Network/networkManagers/networkGroups/staticMembers@2022-11-01"
  count     = length(local.members_ng_trusted_mesh_networks_region1)
  name      = "ng-trusted-mesh-region1-${count.index}"
  parent_id = azapi_resource.ng_trusted_mesh_networks_region1.0.id

  body = jsonencode({
    properties = {
      resourceId = local.members_ng_trusted_mesh_networks_region1[count.index]
    }
  })
  schema_validation_enabled = false
}

# subnets

resource "azapi_resource" "members_ng_hubspoke_mesh_subnets_region1" {
  type      = "Microsoft.Network/networkManagers/networkGroups/staticMembers@2022-11-01"
  count     = length(local.members_ng_hubspoke_mesh_subnets_region1)
  name      = "ng-trusted-mesh-region1-${count.index}"
  parent_id = azapi_resource.ng_hubspoke_mesh_subnets_region1.0.id

  body = jsonencode({
    properties = {
      resourceId = local.members_ng_hubspoke_mesh_subnets_region1[count.index]
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
      name             = "avnm-default-ipv4"
      type             = "AddressPrefix"
      address_prefix   = "0.0.0.0/0"
      next_hop_type    = "VirtualAppliance"
      next_hop_address = module.vhub1.firewall_private_ip
    },
  ]
}

# mesh

resource "azapi_resource" "conn_config_ng_trusted_mesh_networks_region1" {
  type      = "Microsoft.Network/networkManagers/connectivityConfigurations@2022-06-01-preview"
  name      = "conn-config-ng-trusted-mesh-networks-region1"
  parent_id = local.network_manager.id

  body = jsonencode({
    properties = {
      connectivityTopology = "Mesh"
      appliesToGroups = [
        {
          networkGroupId    = azapi_resource.ng_trusted_mesh_networks_region1.0.id
          groupConnectivity = "DirectlyConnected"
          globalMeshEnabled = true
          useHubGateway     = false
        }
      ]
    }
  })
  schema_validation_enabled = false
  depends_on = [
    azapi_resource.members_ng_trusted_mesh_networks_region1,
    azapi_resource.members_ng_hubspoke_mesh_subnets_region1,
  ]
}

# routing

resource "azapi_resource" "routing_config_ng_hubspoke_mesh_subnets_region1" {
  type      = "Microsoft.Network/networkManagers/routingConfigurations@2022-06-01-preview"
  name      = "routing-config-ng-hubspoke-mesh-subnets-region1"
  parent_id = local.network_manager.id

  body = jsonencode({
    properties = {
      description = "Routing configuration for subnet network group region1"
    }
  })
  schema_validation_enabled = false
  depends_on = [
    azapi_resource.members_ng_trusted_mesh_networks_region1,
    azapi_resource.members_ng_hubspoke_mesh_subnets_region1,
  ]
}

resource "azapi_resource" "rule_col_ng_hubspoke_mesh_subnets_region1" {
  type      = "Microsoft.Network/networkManagers/routingConfigurations/ruleCollections@2022-06-01-preview"
  name      = "rule-col-ng-hubspoke-mesh-subnets-region1"
  parent_id = azapi_resource.routing_config_ng_hubspoke_mesh_subnets_region1.id

  body = jsonencode({
    properties = {
      description       = "region1"
      localRouteSetting = "DirectRoutingWithinVNet"
      appliesTo = [
        {
          networkGroupId = azapi_resource.ng_hubspoke_mesh_subnets_region1.0.id
        }
      ]
      disableBgpRoutePropagation = "True"
    }
  })
  schema_validation_enabled = false
  depends_on = [
    azapi_resource.members_ng_trusted_mesh_networks_region1,
    azapi_resource.members_ng_hubspoke_mesh_subnets_region1,
  ]
}

resource "azapi_resource" "rules_ng_hubspoke_mesh_subnets_region1" {
  for_each  = { for r in local.routing_config_hubspoke_rule_col_rules : r.name => r }
  type      = "Microsoft.Network/networkManagers/routingConfigurations/ruleCollections/rules@2022-06-01-preview"
  name      = each.value.name
  parent_id = azapi_resource.rule_col_ng_hubspoke_mesh_subnets_region1.id

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
  depends_on = [
    azapi_resource.members_ng_trusted_mesh_networks_region1,
    azapi_resource.members_ng_hubspoke_mesh_subnets_region1,
  ]
}

####################################################
# deployment
####################################################
/*
# routing

# resource "azapi_resource" "deploy_routing_config_ng_hubspoke_mesh_subnets_region1" {
#   type      = "Microsoft.Network/networkManagers/commit@2022-11-01"
#   name      = "deploy-routing-config-ng-hubspoke-mesh-subnets-region1"
#   parent_id = local.network_manager.id

#   body = jsonencode({
#     properties = {
#       configurationIds = [
#         azapi_resource.routing_config_ng_hubspoke_mesh_subnets_region1.id
#       ],
#       commitType = "Routing",
#       targetLocations = [
#         local.region1
#       ]
#     },
#   })
#   schema_validation_enabled = false
# }
*/
