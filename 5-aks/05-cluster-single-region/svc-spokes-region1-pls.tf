
locals {
  user1_tags = { "lab" = local.prefix, "env" = "prod", "nodeType" = "spoke" }
  user2_tags = { "lab" = local.prefix, "env" = "prod", "nodeType" = "spoke" }
  vm_aks_startup_init_vars = {
    FQDN_USER1 = "user1.${local.user1_dns_zone}"
    FQDN_USER2 = "user2.${local.user2_dns_zone}"
  }
  vm_aks_startup_init_files = {
    "${local.init_dir}/init/aks-startup.sh" = { owner = "root", permissions = "0744", content = templatefile("./scripts/aks-startup.sh", local.vm_aks_startup_init_vars) }
  }
}

# resource group

resource "azurerm_resource_group" "user1_rg" {
  name     = "${local.prefix}_${local.lab_name}_User1_RG"
  location = local.default_region
  tags = {
    prefix   = local.prefix
    lab_name = local.lab_name
  }
}

resource "azurerm_resource_group" "user2_rg" {
  name     = "${local.prefix}_${local.lab_name}_User2_RG"
  location = local.default_region
  tags = {
    prefix   = local.prefix
    lab_name = local.lab_name
  }
}

module "vm_cloud_init_aks" {
  source = "../../modules/cloud-config-gen"
  files = merge(
    local.vm_init_files,
    local.vm_startup_init_files,
    local.vm_aks_startup_init_files,
  )
  packages = [
    "docker.io", "docker-compose", "netcat-traditional", "siege",
  ]
  run_commands = [
    "bash ${local.init_dir}/init/startup.sh",
    "bash ${local.init_dir}/init/aks-startup.sh",
    "docker-compose -f ${local.init_dir}/fastapi/docker-compose-app1-80.yml up -d",
    "docker-compose -f ${local.init_dir}/fastapi/docker-compose-app2-8080.yml up -d",
  ]
}

# user1
#----------------------------

locals {
  user1_prefix        = local.prefix == "" ? "user1-" : join("-", [local.prefix, "user1-"])
  user1_location      = local.region1
  user1_address_space = ["10.1.0.0/16", "fd00:db8:1::/56", ]
  user1_bgp_community = "12076:20001"
  user1_dns_zone      = "salawu.net"
  user1_subnets = {
    ("MainSubnet")               = { address_prefixes = ["10.1.0.0/24", ], address_prefixes_v6 = ["fd00:db8:1::/64", ] }
    ("UntrustSubnet")            = { address_prefixes = ["10.1.1.0/24", ], address_prefixes_v6 = ["fd00:db8:1:1::/64", ], }
    ("TrustSubnet")              = { address_prefixes = ["10.1.2.0/24", ], address_prefixes_v6 = ["fd00:db8:1:2::/64", ], }
    ("ManagementSubnet")         = { address_prefixes = ["10.1.3.0/24", ], address_prefixes_v6 = ["fd00:db8:1:3::/64", ], }
    ("AppGatewaySubnet")         = { address_prefixes = ["10.1.4.0/24", ], address_prefixes_v6 = ["fd00:db8:1:4::/64", ], }
    ("LoadBalancerSubnet")       = { address_prefixes = ["10.1.5.0/24", ], address_prefixes_v6 = ["fd00:db8:1:5::/64", ], }
    ("PrivateLinkServiceSubnet") = { address_prefixes = ["10.1.6.0/24", ], }
    ("PrivateEndpointSubnet")    = { address_prefixes = ["10.1.7.0/24", ], private_endpoint_network_policies = ["Enabled"] }
    ("AppServiceSubnet")         = { address_prefixes = ["10.1.8.0/24", ], address_prefixes_v6 = ["fd00:db8:1:8::/64", ], delegate = ["Microsoft.Web/serverFarms"] }
    ("GatewaySubnet")            = { address_prefixes = ["10.1.9.0/24", ], address_prefixes_v6 = ["fd00:db8:1:9::/64", ], }
    ("TestSubnet")               = { address_prefixes = ["10.1.10.0/24"], }
    ("AksSubnet")                = { address_prefixes = ["10.1.11.0/24", ], address_prefixes_v6 = ["fd00:db8:1:11::/64", ], }
    ("AksPodSubnet")             = { address_prefixes = ["10.1.12.0/22", ], address_prefixes_v6 = ["fd00:db8:1:12::/64", ], }
  }
  user1_vm_addr    = cidrhost(local.user1_subnets["MainSubnet"].address_prefixes[0], 5)
  user1_ilb_addr   = cidrhost(local.user1_subnets["LoadBalancerSubnet"].address_prefixes[0], 99)
  user1_appgw_addr = cidrhost(local.user1_subnets["AppGatewaySubnet"].address_prefixes[0], 99)

  user1_vm_addr_v6    = cidrhost(local.user1_subnets["MainSubnet"].address_prefixes_v6[0], 5)
  user1_ilb_addr_v6   = cidrhost(local.user1_subnets["LoadBalancerSubnet"].address_prefixes_v6[0], 153)
  user1_appgw_addr_v6 = cidrhost(local.user1_subnets["AppGatewaySubnet"].address_prefixes_v6[0], 153)

  user1_pl_nat_addr  = cidrhost(local.user1_subnets["MainSubnet"].address_prefixes[0], 50)
  user1_vm_hostname  = "user1Vm"
  user1_ilb_hostname = "user1-ilb"
  user1_vm_fqdn      = "${local.user1_vm_hostname}.${local.user1_dns_zone}"
}

# user2
#----------------------------

locals {
  user2_prefix        = local.prefix == "" ? "user2-" : join("-", [local.prefix, "user2-"])
  user2_location      = local.region1
  user2_address_space = ["10.2.0.0/16", "fd00:db8:2::/56", ]
  user2_bgp_community = "12076:20002"
  user2_dns_zone      = "salawu.net"
  user2_subnets = {
    ("MainSubnet")               = { address_prefixes = ["10.2.0.0/24", ], address_prefixes_v6 = ["fd00:db8:2::/64"] }
    ("UntrustSubnet")            = { address_prefixes = ["10.2.1.0/24", ], address_prefixes_v6 = ["fd00:db8:2:1::/64"], }
    ("TrustSubnet")              = { address_prefixes = ["10.2.2.0/24", ], address_prefixes_v6 = ["fd00:db8:2:2::/64"], }
    ("ManagementSubnet")         = { address_prefixes = ["10.2.3.0/24", ], address_prefixes_v6 = ["fd00:db8:2:3::/64"], }
    ("AppGatewaySubnet")         = { address_prefixes = ["10.2.4.0/24", ], address_prefixes_v6 = ["fd00:db8:2:4::/64"], }
    ("LoadBalancerSubnet")       = { address_prefixes = ["10.2.5.0/24", ], address_prefixes_v6 = ["fd00:db8:2:5::/64"], }
    ("PrivateLinkServiceSubnet") = { address_prefixes = ["10.2.6.0/24", ], }
    ("PrivateEndpointSubnet")    = { address_prefixes = ["10.2.7.0/24", ], private_endpoint_network_policies = ["Enabled"] }
    ("AppServiceSubnet")         = { address_prefixes = ["10.2.8.0/24", ], address_prefixes_v6 = ["fd00:db8:2:8::/64"], delegate = ["Microsoft.Web/serverFarms"] }
    ("GatewaySubnet")            = { address_prefixes = ["10.2.9.0/24", ], address_prefixes_v6 = ["fd00:db8:2:9::/64"], }
    ("TestSubnet")               = { address_prefixes = ["10.2.10.0/24"], }
    ("AksSubnet")                = { address_prefixes = ["10.2.11.0/24", ], address_prefixes_v6 = ["fd00:db8:2:11::/64", ], }
    ("AksPodSubnet")             = { address_prefixes = ["10.2.12.0/22", ], address_prefixes_v6 = ["fd00:db8:2:12::/64", ], }
  }
  user2_vm_addr    = cidrhost(local.user2_subnets["MainSubnet"].address_prefixes[0], 5)
  user2_ilb_addr   = cidrhost(local.user2_subnets["LoadBalancerSubnet"].address_prefixes[0], 99)
  user2_appgw_addr = cidrhost(local.user2_subnets["AppGatewaySubnet"].address_prefixes[0], 99)

  user2_vm_addr_v6    = cidrhost(local.user2_subnets["MainSubnet"].address_prefixes_v6[0], 5)
  user2_ilb_addr_v6   = cidrhost(local.user2_subnets["LoadBalancerSubnet"].address_prefixes_v6[0], 153)
  user2_appgw_addr_v6 = cidrhost(local.user2_subnets["AppGatewaySubnet"].address_prefixes_v6[0], 153)

  user2_pl_nat_addr  = cidrhost(local.user2_subnets["MainSubnet"].address_prefixes[0], 50)
  user2_vm_hostname  = "user2Vm"
  user2_ilb_hostname = "user2-ilb"
  user2_vm_fqdn      = "${local.user2_vm_hostname}.${local.user2_dns_zone}"
}

module "common_user1" {
  source              = "../../modules/common"
  resource_group      = azurerm_resource_group.user1_rg.name
  env                 = "common"
  prefix              = local.prefix
  firewall_sku        = local.firewall_sku
  regions             = local.regions
  private_prefixes    = local.private_prefixes
  private_prefixes_v6 = local.private_prefixes_v6
  tags                = {}
}

module "common_user2" {
  source              = "../../modules/common"
  resource_group      = azurerm_resource_group.user2_rg.name
  env                 = "common"
  prefix              = local.prefix
  firewall_sku        = local.firewall_sku
  regions             = local.regions
  private_prefixes    = local.private_prefixes
  private_prefixes_v6 = local.private_prefixes_v6
  tags                = {}
}

####################################################
# user1
####################################################

# base

module "user1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.user1_rg.name
  prefix          = trimsuffix(local.user1_prefix, "-")
  env             = "prod"
  location        = local.user1_location
  storage_account = module.common_user1.storage_accounts["region1"]
  tags            = local.user1_tags

  enable_diagnostics                  = local.enable_diagnostics
  enable_ipv6                         = local.enable_ipv6
  log_analytics_workspace_name        = module.common_user1.log_analytics_workspaces["region1"].name
  network_watcher_name                = local.enable_vnet_flow_logs ? "NetworkWatcher_${local.region1}" : null
  network_watcher_resource_group_name = local.enable_vnet_flow_logs ? "NetworkWatcherRG" : null

  private_dns_zones = [
    { name = local.user1_dns_zone },
  ]

  nsg_subnet_map = {
    "MainSubnet"               = module.common_user1.nsg_main["region1"].id
    "UntrustSubnet"            = module.common_user1.nsg_nva["region1"].id
    "TrustSubnet"              = module.common_user1.nsg_main["region1"].id
    "ManagementSubnet"         = module.common_user1.nsg_main["region1"].id
    "AppGatewaySubnet"         = module.common_user1.nsg_lb["region1"].id
    "LoadBalancerSubnet"       = module.common_user1.nsg_default["region1"].id
    "PrivateLinkServiceSubnet" = module.common_user1.nsg_default["region1"].id
    "PrivateEndpointSubnet"    = module.common_user1.nsg_default["region1"].id
    "AppServiceSubnet"         = module.common_user1.nsg_default["region1"].id
    "TestSubnet"               = module.common_user1.nsg_main["region1"].id
    "AksSubnet"                = module.common_user1.nsg_aks["region1"].id
  }

  config_vnet = {
    bgp_community = local.user1_bgp_community
    address_space = local.user1_address_space
    subnets       = local.user1_subnets
    nat_gateway_subnet_names = [
      "MainSubnet",
      "TrustSubnet",
      "TestSubnet",
    ]
  }
  depends_on = [
    module.common_user1,
  ]
}

resource "time_sleep" "user1" {
  create_duration = "90s"
  depends_on = [
    module.user1
  ]
}

# workload

module "user1_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.user1_rg.name
  name            = "${local.prefix}-${local.user1_vm_hostname}"
  computer_name   = local.user1_vm_hostname
  location        = local.user1_location
  storage_account = module.common_user1.storage_accounts["region1"]
  custom_data     = base64encode(module.vm_cloud_init_aks.cloud_config)
  tags            = local.user1_tags

  enable_ipv6 = local.enable_ipv6
  interfaces = [
    {
      name                 = "${local.user1_prefix}vm-main-nic"
      subnet_id            = module.user1.subnets["MainSubnet"].id
      private_ip_address   = local.user1_vm_addr
      private_ipv6_address = local.user1_vm_addr_v6
    },
  ]
  depends_on = [
    time_sleep.user1,
  ]
}

####################################################
# user2
####################################################

# base

module "user2" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.user2_rg.name
  prefix          = trimsuffix(local.user2_prefix, "-")
  env             = "prod"
  location        = local.user2_location
  storage_account = module.common_user2.storage_accounts["region1"]
  tags            = local.user2_tags

  enable_diagnostics                  = local.enable_diagnostics
  enable_ipv6                         = local.enable_ipv6
  log_analytics_workspace_name        = module.common_user2.log_analytics_workspaces["region1"].name
  network_watcher_name                = local.enable_vnet_flow_logs ? "NetworkWatcher_${local.region1}" : null
  network_watcher_resource_group_name = local.enable_vnet_flow_logs ? "NetworkWatcherRG" : null

  private_dns_zones = [
    { name = local.user2_dns_zone },
  ]

  nsg_subnet_map = {
    "MainSubnet"               = module.common_user2.nsg_main["region1"].id
    "UntrustSubnet"            = module.common_user2.nsg_nva["region1"].id
    "TrustSubnet"              = module.common_user2.nsg_main["region1"].id
    "ManagementSubnet"         = module.common_user2.nsg_main["region1"].id
    "AppGatewaySubnet"         = module.common_user2.nsg_lb["region1"].id
    "LoadBalancerSubnet"       = module.common_user2.nsg_default["region1"].id
    "PrivateLinkServiceSubnet" = module.common_user2.nsg_default["region1"].id
    "PrivateEndpointSubnet"    = module.common_user2.nsg_default["region1"].id
    "AppServiceSubnet"         = module.common_user2.nsg_default["region1"].id
    "TestSubnet"               = module.common_user2.nsg_main["region1"].id
    "AksSubnet"                = module.common_user2.nsg_aks["region1"].id
  }

  config_vnet = {
    bgp_community = local.user2_bgp_community
    address_space = local.user2_address_space
    subnets       = local.user2_subnets
    nat_gateway_subnet_names = [
      "MainSubnet",
      "TrustSubnet",
      "TestSubnet",
    ]
  }
  depends_on = [
    module.common_user2,
  ]
}

resource "time_sleep" "user2" {
  create_duration = "90s"
  depends_on = [
    module.user2
  ]
}

# workload

module "user2_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.user2_rg.name
  name            = "${local.prefix}-${local.user2_vm_hostname}"
  computer_name   = local.user2_vm_hostname
  location        = local.user2_location
  storage_account = module.common_user2.storage_accounts["region1"]
  custom_data     = base64encode(module.vm_cloud_init_aks.cloud_config)
  tags            = local.user2_tags

  enable_ipv6 = local.enable_ipv6
  interfaces = [
    {
      name                 = "${local.user2_prefix}vm-main-nic"
      subnet_id            = module.user2.subnets["MainSubnet"].id
      private_ip_address   = local.user2_vm_addr
      private_ipv6_address = local.user2_vm_addr_v6
    },
  ]
  depends_on = [
    time_sleep.user2,
  ]
}

####################################################
# output files
####################################################

locals {
  svc_spokes_region1_files = {
  }
}

resource "local_file" "ssvc_pokes_region1_files" {
  for_each = local.svc_spokes_region1_files
  filename = each.key
  content  = each.value
}
