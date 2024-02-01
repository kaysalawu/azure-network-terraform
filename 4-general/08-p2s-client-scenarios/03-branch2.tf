
locals {
  branch2_init_dir       = "/var/lib/azure"
  branch2_app_name       = "web"
  branch2_app_dir        = "${local.branch2_init_dir}/${local.branch2_app_name}"
  branch2_init_dir_local = "../../scripts/init/${local.branch2_app_name}"
  branch2_app_dir_local  = "../../scripts/init/${local.branch2_app_name}/app/app"
  branch2_init_vars = {
    INIT_DIR            = local.branch2_init_dir
    APP_NAME            = local.branch2_app_name
    USER_ASSIGNED_ID    = azurerm_user_assigned_identity.machine.id
    RESOURCE_GROUP_NAME = azurerm_resource_group.rg.name
    VPN_GATEWAY_NAME    = module.hub1.p2s_vpngw.name
  }
  client2_init_files = {
    "${local.branch2_init_dir}/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("${local.branch2_init_dir_local}/docker-compose.yml", local.branch2_init_vars) }
    "${local.branch2_init_dir}/start.sh"           = { owner = "root", permissions = "0744", content = templatefile("${local.branch2_init_dir_local}/start.sh", local.branch2_init_vars) }
    "${local.branch2_init_dir}/stop.sh"            = { owner = "root", permissions = "0744", content = templatefile("${local.branch2_init_dir_local}/stop.sh", local.branch2_init_vars) }
    "${local.branch2_init_dir}/service.sh"         = { owner = "root", permissions = "0744", content = templatefile("${local.branch2_init_dir_local}/service.sh", local.branch2_init_vars) }
    "${local.branch2_init_dir}/tools.sh"           = { owner = "root", permissions = "0744", content = local.tools }
    "${local.branch2_init_dir}/client-config.sh"   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/p2s/client-config.sh", local.branch2_init_vars) }
    "${local.branch2_init_dir}/client2_cert.pem"   = { owner = "root", permissions = "0400", content = trimspace(module.hub1.p2s_client_certificates_cert_pem["client2"]) }
    "${local.branch2_init_dir}/client2_key.pem"    = { owner = "root", permissions = "0400", content = trimspace(module.hub1.p2s_client_certificates_private_key_pem["client2"]) }

    "${local.branch2_app_dir}/Dockerfile"       = { owner = "root", permissions = "0744", content = templatefile("${local.branch2_app_dir_local}/Dockerfile", local.branch2_init_vars) }
    "${local.branch2_app_dir}/.dockerignore"    = { owner = "root", permissions = "0744", content = templatefile("${local.branch2_app_dir_local}/.dockerignore", local.branch2_init_vars) }
    "${local.branch2_app_dir}/main.py"          = { owner = "root", permissions = "0744", content = templatefile("${local.branch2_app_dir_local}/main.py", local.branch2_init_vars) }
    "${local.branch2_app_dir}/_app.py"          = { owner = "root", permissions = "0744", content = templatefile("${local.branch2_app_dir_local}/_app.py", local.branch2_init_vars) }
    "${local.branch2_app_dir}/requirements.txt" = { owner = "root", permissions = "0744", content = templatefile("${local.branch2_app_dir_local}/requirements.txt", local.branch2_init_vars) }
  }
  client3_init_files = {
    "${local.branch2_init_dir}/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("${local.branch2_init_dir_local}/docker-compose.yml", local.branch2_init_vars) }
    "${local.branch2_init_dir}/start.sh"           = { owner = "root", permissions = "0744", content = templatefile("${local.branch2_init_dir_local}/start.sh", local.branch2_init_vars) }
    "${local.branch2_init_dir}/stop.sh"            = { owner = "root", permissions = "0744", content = templatefile("${local.branch2_init_dir_local}/stop.sh", local.branch2_init_vars) }
    "${local.branch2_init_dir}/service.sh"         = { owner = "root", permissions = "0744", content = templatefile("${local.branch2_init_dir_local}/service.sh", local.branch2_init_vars) }
    "${local.branch2_init_dir}/tools.sh"           = { owner = "root", permissions = "0744", content = local.tools }
    "${local.branch2_init_dir}/client-config.sh"   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/p2s/client-config.sh", local.branch2_init_vars) }
    "${local.branch2_init_dir}/client3_cert.pem"   = { owner = "root", permissions = "0400", content = trimspace(module.hub1.p2s_client_certificates_cert_pem["client3"]) }
    "${local.branch2_init_dir}/client3_key.pem"    = { owner = "root", permissions = "0400", content = trimspace(module.hub1.p2s_client_certificates_private_key_pem["client3"]) }

    "${local.branch2_app_dir}/Dockerfile"       = { owner = "root", permissions = "0744", content = templatefile("${local.branch2_app_dir_local}/Dockerfile", local.branch2_init_vars) }
    "${local.branch2_app_dir}/.dockerignore"    = { owner = "root", permissions = "0744", content = templatefile("${local.branch2_app_dir_local}/.dockerignore", local.branch2_init_vars) }
    "${local.branch2_app_dir}/main.py"          = { owner = "root", permissions = "0744", content = templatefile("${local.branch2_app_dir_local}/main.py", local.branch2_init_vars) }
    "${local.branch2_app_dir}/_app.py"          = { owner = "root", permissions = "0744", content = templatefile("${local.branch2_app_dir_local}/_app.py", local.branch2_init_vars) }
    "${local.branch2_app_dir}/requirements.txt" = { owner = "root", permissions = "0744", content = templatefile("${local.branch2_app_dir_local}/requirements.txt", local.branch2_init_vars) }
  }
  branch2_vm_init = templatefile("../../scripts/server.sh", {
    USER_ASSIGNED_ID          = azurerm_user_assigned_identity.machine.id
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
    ENABLE_TRAFFIC_GEN        = true
  })
}

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

  nsg_subnet_map = {
    "MainSubnet"      = module.common.nsg_main["region1"].id
    "TrustSubnet"     = module.common.nsg_main["region1"].id
    "UntrustSubnet"   = module.common.nsg_nva["region1"].id
    "DnsServerSubnet" = module.common.nsg_main["region1"].id
  }

  config_vnet = {
    address_space = local.branch2_address_space
    subnets       = local.branch2_subnets
  }

  config_ergw = {
    enable             = true
    sku                = "ErGw1AZ"
    enable_diagnostics = local.enable_diagnostics
  }

  depends_on = [
    module.common,
  ]
}

####################################################
# dns
####################################################

module "branch2_dns" {
  source           = "../../modules/linux"
  resource_group   = azurerm_resource_group.rg.name
  prefix           = local.branch2_prefix
  name             = "dns"
  location         = local.branch2_location
  subnet           = module.branch2.subnets["MainSubnet"].id
  private_ip       = local.branch2_dns_addr
  enable_public_ip = true
  source_image     = "ubuntu-20"
  custom_data      = base64encode(local.branch_unbound_startup)
  storage_account  = module.common.storage_accounts["region1"]
  tags             = local.branch2_tags
}

####################################################
# p2s clients
####################################################

# client2
#----------------------------------------
# uses public ip of p2s gateway
# untrust udr is used to route traffic to p2s gateway
# it bypasses default internet

module "client2_init" {
  source = "../../modules/cloud-config-gen"
  packages = [
    "docker.io", "docker-compose",
  ]
  files = local.client2_init_files
  run_commands = [
    ". ${local.branch2_init_dir}/service.sh",
    ". ${local.branch2_init_dir}/tools.sh",
    "echo 'RESOURCE_GROUP_NAME=${azurerm_resource_group.rg.name}' >> ${local.branch2_init_dir}/.env",
    "echo 'VPN_GATEWAY_NAME=${module.hub1.p2s_vpngw.name}' >> ${local.branch2_init_dir}/.env",
    #"echo 'VPN_GATEWAY_IP=${azurerm_public_ip.hub1_p2s_vpngw_pip.ip_address}' >> ${local.branch2_init_dir}/.env",
    #"echo 'VPN_GATEWAY_IP=${local.hub1_nva_trust_addr}' >> ${local.branch2_init_dir}/.env",
  ]
}


module "client2" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.branch2_prefix}client2"
  location        = local.branch2_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.client2_init.cloud_config)
  identity_ids    = [azurerm_user_assigned_identity.machine.id, ]
  tags            = local.branch2_tags

  enable_ip_forwarding = true

  interfaces = [
    {
      name             = "${local.branch2_prefix}client2-untrust"
      subnet_id        = module.branch2.subnets["UntrustSubnet"].id
      create_public_ip = true
    },
    {
      name      = "${local.branch2_prefix}client2-trust"
      subnet_id = module.branch2.subnets["TrustSubnet"].id
    },
  ]
  depends_on = [module.branch2]
}

# client2
#----------------------------------------
# uses private ip of p2s gateway
# openvpn tunnel not working

module "client3_init" {
  source = "../../modules/cloud-config-gen"
  packages = [
    "docker.io", "docker-compose",
  ]
  files = local.client3_init_files
  run_commands = [
    ". ${local.branch2_init_dir}/service.sh",
    ". ${local.branch2_init_dir}/tools.sh",
    "echo 'RESOURCE_GROUP_NAME=${azurerm_resource_group.rg.name}' >> ${local.branch2_init_dir}/.env",
    "echo 'VPN_GATEWAY_NAME=${module.hub1.p2s_vpngw.name}' >> ${local.branch2_init_dir}/.env",
    #"echo 'VPN_GATEWAY_IP=${azurerm_public_ip.hub1_p2s_vpngw_pip.ip_address}' >> ${local.branch2_init_dir}/.env",
    "echo 'VPN_GATEWAY_IP=${local.hub1_nva_trust_addr}' >> ${local.branch2_init_dir}/.env",
  ]
}

module "client3" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.branch2_prefix}client3"
  location        = local.branch2_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.client3_init.cloud_config)
  identity_ids    = [azurerm_user_assigned_identity.machine.id, ]
  tags            = local.branch2_tags

  enable_ip_forwarding = true

  interfaces = [
    {
      name             = "${local.branch2_prefix}client3-untrust"
      subnet_id        = module.branch2.subnets["UntrustSubnet"].id
      create_public_ip = true
    },
    {
      name      = "${local.branch2_prefix}client3-trust"
      subnet_id = module.branch2.subnets["TrustSubnet"].id
    },
  ]
  depends_on = [module.branch2]
}

####################################################
# workload
####################################################

module "branch2_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.branch2_prefix}vm"
  computer_name   = "vm"
  location        = local.branch2_location
  storage_account = module.common.storage_accounts["region1"]
  dns_servers     = [local.branch2_dns_addr, ]
  custom_data     = base64encode(local.branch2_vm_init)
  identity_ids    = [azurerm_user_assigned_identity.machine.id, ]
  tags            = local.branch2_tags

  interfaces = [
    {
      name               = "${local.branch2_prefix}vm-main-nic"
      subnet_id          = module.branch2.subnets["MainSubnet"].id
      private_ip_address = local.branch2_vm_addr
      create_public_ip   = true
    },
  ]
  depends_on = [
    module.branch2
  ]
}

####################################################
# udr
####################################################

# main

locals {
  branch2_routes_main = [
    # {
    #   name                   = "p2s-gw"
    #   address_prefix         = ["${azurerm_public_ip.hub1_p2s_vpngw_pip.ip_address}/32"]
    #   next_hop_type          = "VirtualAppliance"
    #   next_hop_in_ip_address = local.hub1_nva_trust_addr
    # },
  ]
}

module "branch2_udr_main" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.branch2_prefix}main"
  location       = local.branch2_location
  subnet_id      = module.branch2.subnets["MainSubnet"].id
  routes         = local.branch2_routes_main

  disable_bgp_route_propagation = false
  depends_on = [
    module.branch2,
    module.branch2_dns,
  ]
}

####################################################
# output files
####################################################

locals {
  branch2_files = {
    "output/branch2-vm.sh"         = local.branch2_vm_init
    "output/branch2-p2s-client.sh" = module.client2_init.cloud_config
  }
}

resource "local_file" "branch2_files" {
  for_each = local.branch2_files
  filename = each.key
  content  = each.value
}
