
####################################################
# spoke1
####################################################

# base

module "spoke1" {
  source            = "../../modules/base"
  resource_group    = azurerm_resource_group.rg.name
  prefix            = trimsuffix(local.spoke1_prefix, "-")
  env               = "prod"
  location          = local.spoke1_location
  storage_account   = module.common.storage_accounts["region1"]
  user_assigned_ids = [azurerm_user_assigned_identity.machine.id, ]
  tags              = local.spoke1_tags

  enable_diagnostics           = local.enable_diagnostics
  log_analytics_workspace_name = module.common.log_analytics_workspaces["region1"].name

  dns_zones_linked_to_vnet = [
    { name = module.common.private_dns_zones[local.region1_dns_zone].name, registration_enabled = true },
  ]

  nsg_subnet_map = {
    "MainSubnet"               = module.common.nsg_main["region1"].id
    "UntrustSubnet"            = module.common.nsg_open["region1"].id
    "TrustSubnet"              = module.common.nsg_main["region1"].id
    "ManagementSubnet"         = module.common.nsg_main["region1"].id
    "AppGatewaySubnet"         = module.common.nsg_lb["region1"].id
    "LoadBalancerSubnet"       = module.common.nsg_default["region1"].id
    "PrivateLinkServiceSubnet" = module.common.nsg_default["region1"].id
    "PrivateEndpointSubnet"    = module.common.nsg_default["region1"].id
    "AppServiceSubnet"         = module.common.nsg_default["region1"].id
  }

  config_vnet = {
    address_space = local.spoke1_address_space
    subnets       = local.spoke1_subnets
    nat_gateway_subnet_names = [
      "MainSubnet",
      "UntrustSubnet",
    ]
  }
  depends_on = [
    module.common,
  ]
}

# workload

locals {
  spoke1_vm_init = templatefile("../../scripts/server.sh", {
    USER_ASSIGNED_ID          = azurerm_user_assigned_identity.machine.id
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
    ENABLE_TRAFFIC_GEN        = true
  })
}

module "spoke1_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.spoke1_vm_hostname}"
  computer_name   = local.spoke1_vm_hostname
  location        = local.spoke1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.spoke1_vm_init)
  tags            = local.spoke1_tags

  interfaces = [
    {
      name               = "${local.spoke1_prefix}vm-main-nic"
      subnet_id          = module.spoke1.subnets["MainSubnet"].id
      private_ip_address = local.spoke1_vm_addr
    },
  ]
  depends_on = [
    module.spoke1
  ]
}

####################################################
# backends
####################################################

locals {
  spoke1_be_dir = "/var/lib/spoke"
  spoke1_be_vars = {
    INIT_DIR = local.spoke1_be_dir
  }
}

module "spoke1_be1" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.spoke1_prefix}be1"
  computer_name   = "be1"
  location        = local.spoke1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.web_http_backend_init.cloud_config)
  tags            = local.spoke1_tags

  interfaces = [
    {
      name      = "${local.spoke1_prefix}vm-main-nic"
      subnet_id = module.spoke1.subnets["MainSubnet"].id
    },
  ]
  depends_on = [
    module.spoke1
  ]
}

module "spoke1_be2" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.spoke1_prefix}be2"
  computer_name   = "be2"
  location        = local.spoke1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.web_http_backend_init.cloud_config)
  tags            = local.spoke1_tags

  interfaces = [
    {
      name      = "${local.spoke1_prefix}vm-main-nic"
      subnet_id = module.spoke1.subnets["MainSubnet"].id
    },
  ]
  depends_on = [
    module.spoke1
  ]
}

####################################################
# output files
####################################################

locals {
  spoke1_files = {
    "output/spoke1-be-init" = module.web_http_backend_init.cloud_config
  }
}

resource "local_file" "spoke1_files" {
  for_each = local.spoke1_files
  filename = each.key
  content  = each.value
}
