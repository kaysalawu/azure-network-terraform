
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
  }

  config_vnet = {
    address_space = local.branch1_address_space
    subnets       = local.branch1_subnets
    nat_gateway_subnet_names = [
      "MainSubnet",
      "TrustSubnet",
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

####################################################
# dns
####################################################

locals {
  branch1_unbound_startup = templatefile("../../scripts/unbound/unbound.sh", local.branch1_dns_vars)
  branch1_dns_vars = {
    ONPREM_LOCAL_RECORDS = local.onprem_local_records
    REDIRECTED_HOSTS     = local.onprem_redirected_hosts
    FORWARD_ZONES        = local.branch1_forward_zones
    TARGETS              = local.vm_script_targets
    ACCESS_CONTROL_PREFIXES = concat(
      local.private_prefixes,
      ["127.0.0.0/8", "35.199.192.0/19", ]
    )
  }
  branch1_forward_zones = [
    { zone = "${local.region1_dns_zone}.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "${local.region2_dns_zone}.", targets = [local.hub2_dns_in_addr, ] },
    { zone = "privatelink.blob.core.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.azurewebsites.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.database.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.table.cosmos.azure.com.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.queue.core.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.file.core.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = ".", targets = [local.azuredns, ] },
  ]
}

module "branch1_dns" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.branch1_dns_hostname}"
  computer_name   = local.branch1_dns_hostname
  location        = local.branch1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.branch1_unbound_startup)
  tags            = local.branch1_tags

  interfaces = [
    {
      name               = "${local.branch1_prefix}dns-main"
      subnet_id          = module.branch1.subnets["MainSubnet"].id
      private_ip_address = local.branch1_dns_addr
    },
  ]
}

####################################################
# p2s client
####################################################

locals {
  branch1_init_dir       = "/var/lib/azure"
  branch1_app_name       = "web"
  branch1_app_dir        = "${local.branch1_init_dir}/${local.branch1_app_name}"
  branch1_init_dir_local = "../../scripts/init/${local.branch1_app_name}"
  branch1_app_dir_local  = "../../scripts/init/${local.branch1_app_name}/app/app"
  branch1_init_vars = {
    INIT_DIR            = local.branch1_init_dir
    APP_NAME            = local.branch1_app_name
    RESOURCE_GROUP_NAME = azurerm_resource_group.rg.name
    VPN_GATEWAY_NAME    = module.hub1.p2s_vpngw.name
  }
  client1_init_files = {
    "${local.branch1_init_dir}/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("${local.branch1_init_dir_local}/docker-compose.yml", local.branch1_init_vars) }
    "${local.branch1_init_dir}/start.sh"           = { owner = "root", permissions = "0744", content = templatefile("${local.branch1_init_dir_local}/start.sh", local.branch1_init_vars) }
    "${local.branch1_init_dir}/stop.sh"            = { owner = "root", permissions = "0744", content = templatefile("${local.branch1_init_dir_local}/stop.sh", local.branch1_init_vars) }
    "${local.branch1_init_dir}/service.sh"         = { owner = "root", permissions = "0744", content = templatefile("${local.branch1_init_dir_local}/service.sh", local.branch1_init_vars) }
    "${local.branch1_init_dir}/server.sh"          = { owner = "root", permissions = "0744", content = local.vm_startup }
    "${local.branch1_init_dir}/client-config.sh"   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/p2s/client-config.sh", local.branch1_init_vars) }
    "${local.branch1_init_dir}/client1_cert.pem"   = { owner = "root", permissions = "0400", content = trimspace(module.hub1.p2s_client_certificates_cert_pem["client1"]) }
    "${local.branch1_init_dir}/client1_key.pem"    = { owner = "root", permissions = "0400", content = trimspace(module.hub1.p2s_client_certificates_private_key_pem["client1"]) }

    "${local.branch1_app_dir}/Dockerfile"       = { owner = "root", permissions = "0744", content = templatefile("${local.branch1_app_dir_local}/Dockerfile", local.branch1_init_vars) }
    "${local.branch1_app_dir}/.dockerignore"    = { owner = "root", permissions = "0744", content = templatefile("${local.branch1_app_dir_local}/.dockerignore", local.branch1_init_vars) }
    "${local.branch1_app_dir}/main.py"          = { owner = "root", permissions = "0744", content = templatefile("${local.branch1_app_dir_local}/main.py", local.branch1_init_vars) }
    "${local.branch1_app_dir}/_app.py"          = { owner = "root", permissions = "0744", content = templatefile("${local.branch1_app_dir_local}/_app.py", local.branch1_init_vars) }
    "${local.branch1_app_dir}/requirements.txt" = { owner = "root", permissions = "0744", content = templatefile("${local.branch1_app_dir_local}/requirements.txt", local.branch1_init_vars) }
  }
}

# cloud-init

module "branch1_vm_p2s_init" {
  source = "../../modules/cloud-config-gen"
  packages = [
    "docker.io", "docker-compose", #npm,
  ]
  files = local.client1_init_files
  run_commands = [
    "bash ${local.branch1_init_dir}/server.sh",
    "bash ${local.branch1_init_dir}/service.sh",
    "echo 'RESOURCE_GROUP_NAME=${azurerm_resource_group.rg.name}' >> ${local.branch1_init_dir}/.env",
    "echo 'VPN_GATEWAY_NAME=${module.hub1.p2s_vpngw.name}' >> ${local.branch1_init_dir}/.env",
  ]
}

module "client1" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-client1"
  computer_name   = "client1"
  location        = local.branch1_location
  storage_account = module.common.storage_accounts["region1"]
  dns_servers     = [local.branch1_dns_addr, ]
  custom_data     = base64encode(module.branch1_vm_p2s_init.cloud_config)
  tags            = local.branch1_tags

  source_image_publisher = "Canonical"
  source_image_offer     = "0001-com-ubuntu-server-focal"
  source_image_sku       = "20_04-lts"
  source_image_version   = "latest"

  ip_forwarding_enabled = true
  interfaces = [
    {
      name      = "${local.branch1_prefix}client1-untrust-nic"
      subnet_id = module.branch1.subnets["UntrustSubnet"].id
    },
    {
      name      = "${local.branch1_prefix}client1-trust-nic"
      subnet_id = module.branch1.subnets["TrustSubnet"].id
    },
  ]
  depends_on = [module.branch1]
}

####################################################
# workload
####################################################

locals {
  branch1_vm_init = templatefile("../../scripts/server.sh", {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
    ENABLE_TRAFFIC_GEN        = true
  })
}

module "branch1_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.branch1_vm_hostname}"
  computer_name   = local.branch1_vm_hostname
  location        = local.branch1_location
  storage_account = module.common.storage_accounts["region1"]
  dns_servers     = [local.branch1_dns_addr, ]
  custom_data     = base64encode(local.branch1_vm_init)
  tags            = local.branch1_tags

  interfaces = [
    {
      name               = "${local.branch1_prefix}vm-main-nic"
      subnet_id          = module.branch1.subnets["MainSubnet"].id
      private_ip_address = local.branch1_vm_addr
    },
  ]
  depends_on = [
    module.branch1,
    module.branch1_dns,
  ]
}

####################################################
# udr
####################################################

# main

locals {
  branch1_routes_main = []
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
    module.branch1,
    module.branch1_dns,
  ]
}

####################################################
# output files
####################################################

locals {
  branch1_files = {
    "output/branch1-p2s-client.sh" = module.branch1_vm_p2s_init.cloud_config
    "output/branch1Dns.sh"         = local.branch1_unbound_startup
    "output/branch1Vm.sh"          = local.branch1_vm_init
  }
}

resource "local_file" "branch1_files" {
  for_each = local.branch1_files
  filename = each.key
  content  = each.value
}
