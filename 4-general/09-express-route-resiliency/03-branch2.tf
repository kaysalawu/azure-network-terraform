
####################################################
# vnet
####################################################

# base
#----------------------------

module "branch2" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.branch2_prefix, "-")
  location        = local.branch2_location
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.branch2_tags

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
    bgp_community = local.branch2_bgp_community
    address_space = local.branch2_address_space
    subnets       = local.branch2_subnets
    nat_gateway_subnet_names = [
      "MainSubnet",
      "TrustSubnet",
      "DnsServerSubnet",
      "TestSubnet",
    ]
  }

  config_ergw = {
    enable = true
    sku    = "ErGw1AZ"
  }

  config_s2s_vpngw = {
    enable = false
    sku    = "VpnGw1AZ"
  }

  depends_on = [
    module.common,
  ]
}

resource "time_sleep" "branch2" {
  create_duration = "90s"
  depends_on = [
    module.branch2
  ]
}

####################################################
# dns
####################################################

locals {
  branch2_unbound_startup = templatefile("../../scripts/unbound/unbound.sh", local.branch2_dns_vars)
  branch2_dns_vars = {
    ONPREM_LOCAL_RECORDS = local.onprem_local_records
    REDIRECTED_HOSTS     = local.onprem_redirected_hosts
    FORWARD_ZONES        = local.branch2_forward_zones
    TARGETS              = local.vm_script_targets
    ACCESS_CONTROL_PREFIXES = concat(
      local.private_prefixes,
      ["127.0.0.0/8", "35.199.192.0/19", "fd00::/8", ]
    )
  }
  branch2_forward_zones = [
    { zone = "${local.region1_dns_zone}.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.blob.core.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.azurewebsites.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.database.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.table.cosmos.azure.com.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.queue.core.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.file.core.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = ".", targets = [local.azuredns, ] },
  ]
}

module "branch2_dns" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.branch2_dns_hostname}"
  computer_name   = local.branch2_dns_hostname
  location        = local.branch2_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.branch2_unbound_startup)
  tags            = local.branch2_tags

  enable_ipv6 = local.enable_ipv6
  interfaces = [
    {
      name                 = "${local.branch2_prefix}dns-main"
      subnet_id            = module.branch2.subnets["MainSubnet"].id
      private_ip_address   = local.branch2_dns_addr
      private_ipv6_address = local.branch2_dns_addr_v6
    },
  ]
  depends_on = [
    time_sleep.branch2,
  ]
}

####################################################
# workload
####################################################

module "branch2_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.branch2_vm_hostname}"
  computer_name   = local.branch2_vm_hostname
  location        = local.branch2_location
  storage_account = module.common.storage_accounts["region1"]
  dns_servers     = [local.branch2_dns_addr, ]
  custom_data     = base64encode(module.probe_vm_cloud_init.cloud_config)
  tags            = local.branch2_tags

  enable_ipv6 = local.enable_ipv6
  interfaces = [
    {
      name                 = "${local.branch2_prefix}vm-main-nic"
      subnet_id            = module.branch2.subnets["MainSubnet"].id
      private_ip_address   = local.branch2_vm_addr
      private_ipv6_address = local.branch2_vm_addr_v6
      create_public_ip     = true
    },
  ]
  depends_on = [
    module.branch2_dns,
    time_sleep.branch2,
  ]
}

####################################################
# udr
####################################################

# main

locals {
  branch2_routes_main = [
  ]
}

module "branch2_udr_main" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.branch2_prefix}main"
  location       = local.branch2_location
  subnet_ids     = [module.branch2.subnets["MainSubnet"].id, ]
  routes         = local.branch2_routes_main

  disable_bgp_route_propagation = false
  depends_on = [
    module.branch2_dns,
    time_sleep.branch2,
  ]
}

####################################################
# output files
####################################################

locals {
  branch2_files = {
    "output/branch2Dns.sh" = local.branch2_unbound_startup
  }
}

resource "local_file" "branch2_files" {
  for_each = local.branch2_files
  filename = each.key
  content  = each.value
}
