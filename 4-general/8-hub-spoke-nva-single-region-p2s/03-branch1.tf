
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

  nsg_subnet_map = {
    "MainSubnet"      = module.common.nsg_main["region1"].id
    "TrustSubnet"     = module.common.nsg_main["region1"].id
    "UntrustSubnet"   = module.common.nsg_nva["region1"].id
    "DnsServerSubnet" = module.common.nsg_main["region1"].id
  }

  config_vnet = {
    address_space = local.branch1_address_space
    subnets       = local.branch1_subnets
  }

  depends_on = [
    module.common,
  ]
}

####################################################
# dns
####################################################

module "branch1_dns" {
  source           = "../../modules/linux"
  resource_group   = azurerm_resource_group.rg.name
  prefix           = local.branch1_prefix
  name             = "dns"
  location         = local.branch1_location
  subnet           = module.branch1.subnets["MainSubnet"].id
  private_ip       = local.branch1_dns_addr
  enable_public_ip = true
  source_image     = "ubuntu-20"
  custom_data      = base64encode(local.branch_unbound_startup)
  storage_account  = module.common.storage_accounts["region1"]
  tags             = local.branch1_tags
}

####################################################
# p2s client
####################################################

locals {
  init_dir       = "/var/lib/azure"
  app_name       = "web"
  app_dir        = "${local.init_dir}/${local.app_name}"
  init_dir_local = "../../scripts/init/${local.app_name}"
  app_dir_local  = "../../scripts/init/${local.app_name}/app/app"
  init_vars = {
    INIT_DIR         = local.init_dir
    APP_NAME         = local.app_name
    USER_ASSIGNED_ID = azurerm_user_assigned_identity.machine.id
  }
  vm_p2s_init_files = {
    "${local.init_dir}/docker-compose.yml"   = { owner = "root", permissions = "0744", content = templatefile("${local.init_dir_local}/docker-compose.yml", local.init_vars) }
    "${local.init_dir}/start.sh"             = { owner = "root", permissions = "0744", content = templatefile("${local.init_dir_local}/start.sh", local.init_vars) }
    "${local.init_dir}/stop.sh"              = { owner = "root", permissions = "0744", content = templatefile("${local.init_dir_local}/stop.sh", local.init_vars) }
    "${local.init_dir}/service.sh"           = { owner = "root", permissions = "0744", content = templatefile("${local.init_dir_local}/service.sh", local.init_vars) }
    "${local.init_dir}/tools.sh"             = { owner = "root", permissions = "0744", content = local.server_scripts }
    "${local.init_dir}/client-config-gen.sh" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/p2s/client-config-gen.sh", local.init_vars) }
    "${local.init_dir}/client1_cert.pem"     = { owner = "root", permissions = "0400", content = trimspace(module.hub1.p2s_client_certificates_cert_pem["client1"]) }
    "${local.init_dir}/client1_key.pem"      = { owner = "root", permissions = "0400", content = trimspace(module.hub1.p2s_client_certificates_private_key_pem["client1"]) }

    "${local.app_dir}/Dockerfile"       = { owner = "root", permissions = "0744", content = templatefile("${local.app_dir_local}/Dockerfile", local.init_vars) }
    "${local.app_dir}/.dockerignore"    = { owner = "root", permissions = "0744", content = templatefile("${local.app_dir_local}/.dockerignore", local.init_vars) }
    "${local.app_dir}/main.py"          = { owner = "root", permissions = "0744", content = templatefile("${local.app_dir_local}/main.py", local.init_vars) }
    "${local.app_dir}/_app.py"          = { owner = "root", permissions = "0744", content = templatefile("${local.app_dir_local}/_app.py", local.init_vars) }
    "${local.app_dir}/requirements.txt" = { owner = "root", permissions = "0744", content = templatefile("${local.app_dir_local}/requirements.txt", local.init_vars) }
  }
  branch1_vm_init = templatefile("../../scripts/server.sh", {
    USER_ASSIGNED_ID          = azurerm_user_assigned_identity.machine.id
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
    ENABLE_TRAFFIC_GEN        = true
  })
}

# cloud-init

module "vm_p2s_init" {
  source = "../../modules/cloud-config-gen"
  packages = [
    "docker.io", "docker-compose",
  ]
  files = local.vm_p2s_init_files
  run_commands = [
    ". ${local.init_dir}/service.sh",
    ". ${local.init_dir}/tools.sh",
  ]
}

module "branch1_p2s" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.branch1_prefix, "-")
  name            = "p2s"
  location        = local.branch1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.vm_p2s_init.cloud_config)
  identity_ids    = [azurerm_user_assigned_identity.machine.id, ]

  enable_ip_forwarding = true

  interfaces = [
    {
      name             = "untrust"
      subnet_id        = module.branch1.subnets["UntrustSubnet"].id
      create_public_ip = true
    },
    {
      name      = "trust"
      subnet_id = module.branch1.subnets["TrustSubnet"].id
    },
  ]
  depends_on = [module.branch1]
}

####################################################
# workload
####################################################

module "branch1_vm" {
  source           = "../../modules/linux"
  resource_group   = azurerm_resource_group.rg.name
  prefix           = local.branch1_prefix
  name             = "vm"
  location         = local.branch1_location
  subnet           = module.branch1.subnets["MainSubnet"].id
  private_ip       = local.branch1_vm_addr
  enable_public_ip = true
  source_image     = "ubuntu-20"
  dns_servers      = [local.branch1_dns_addr, ]
  custom_data      = base64encode(local.branch1_vm_init)
  storage_account  = module.common.storage_accounts["region1"]
  delay_creation   = "60s"
  tags             = local.branch1_tags

  depends_on = [
    module.branch1,
    module.branch1_dns,
  ]
}

####################################################
# udr
####################################################

# main

module "branch1_udr_main" {
  source                        = "../../modules/udr"
  resource_group                = azurerm_resource_group.rg.name
  prefix                        = "${local.branch1_prefix}main"
  location                      = local.branch1_location
  subnet_id                     = module.branch1.subnets["MainSubnet"].id
  next_hop_type                 = "VirtualAppliance"
  next_hop_in_ip_address        = local.branch1_nva_trust_addr
  destinations                  = local.private_prefixes_map
  delay_creation                = "90s"
  disable_bgp_route_propagation = true
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
    "output/branch1-p2s-client.sh" = module.vm_p2s_init.cloud_config
  }
}

resource "local_file" "branch1_files" {
  for_each = local.branch1_files
  filename = each.key
  content  = each.value
}
