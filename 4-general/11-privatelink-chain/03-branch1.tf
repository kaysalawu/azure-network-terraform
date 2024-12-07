
####################################################
# vnet
####################################################

# base
#----------------------------

module "branch1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.branch1_prefix, "-")
  location        = local.branch1_location
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.branch1_tags

  enable_diagnostics           = local.enable_diagnostics
  log_analytics_workspace_name = module.common.log_analytics_workspaces["region1"].name
  enable_ipv6                  = local.enable_ipv6

  nsg_subnet_map = {
    "MainSubnet"      = module.common.nsg_main["region1"].id
    "UntrustSubnet"   = module.common.nsg_nva["region1"].id
    "TrustSubnet"     = module.common.nsg_main["region1"].id
    "DnsServerSubnet" = module.common.nsg_main["region1"].id
    "TestSubnet"      = module.common.nsg_main["region1"].id
  }

  config_vnet = {
    bgp_community = local.branch1_bgp_community
    address_space = local.branch1_address_space
    subnets       = local.branch1_subnets
    nat_gateway_subnet_names = [
      "MainSubnet",
      "TrustSubnet",
      "DnsServerSubnet",
      "TestSubnet",
    ]
  }

  config_ergw = {
    enable = false
    sku    = "ErGw1AZ"
  }

  depends_on = [
    module.common,
  ]
}

resource "time_sleep" "branch1" {
  create_duration = "90s"
  depends_on = [
    module.branch1
  ]
}

####################################################
# workload
####################################################

module "branch1_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.branch1_vm_hostname}"
  computer_name   = local.branch1_vm_hostname
  location        = local.branch1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.probe_vm_cloud_init.cloud_config)
  tags            = local.branch1_tags

  enable_ipv6 = local.enable_ipv6
  interfaces = [
    {
      name                 = "${local.branch1_prefix}vm-main-nic"
      subnet_id            = module.branch1.subnets["MainSubnet"].id
      private_ip_address   = local.branch1_vm_addr
      private_ipv6_address = local.branch1_vm_addr_v6
    },
  ]
  depends_on = [
    time_sleep.branch1,
  ]
}

####################################################
# udr
####################################################

# main

locals {
  branch1_routes_main = [
    {
      name                   = "private"
      address_prefix         = local.private_prefixes
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = local.branch1_nva_untrust_addr
    },
  ]
}

module "branch1_udr_main" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.branch1_prefix}main"
  location       = local.branch1_location
  subnet_ids     = [module.branch1.subnets["MainSubnet"].id, ]
  routes         = local.branch1_routes_main

  bgp_route_propagation_enabled = false
  depends_on = [
    module.branch1_dns,
    module.branch1_nva,
    time_sleep.branch1,
  ]
}

####################################################
# output files
####################################################

locals {
  branch1_files = {
    "output/branch1Dns.sh" = local.branch1_unbound_startup
    "output/branch1Nva.sh" = local.branch1_nva_init
  }
}

resource "local_file" "branch1_files" {
  for_each = local.branch1_files
  filename = each.key
  content  = each.value
}
