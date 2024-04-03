
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

  enable_diagnostics = local.enable_diagnostics

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

  config_ergw = {
    enable = true
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
  branch1_unbound_files = {
    "${local.branch_dns_init_dir}/unbound/Dockerfile"         = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/Dockerfile", {}) }
    "${local.branch_dns_init_dir}/unbound/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/docker-compose.yml", {}) }
    "/etc/unbound/unbound.conf"                               = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/unbound.conf", local.branch1_dns_vars) }
    "/etc/unbound/unbound.log"                                = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/unbound.log", local.branch1_dns_vars) }
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

module "branch1_unbound_init" {
  source   = "../../modules/cloud-config-gen"
  packages = ["docker.io", "docker-compose", "dnsutils", "net-tools", ]
  files    = local.branch1_unbound_files
  run_commands = [
    "systemctl stop systemd-resolved",
    "systemctl disable systemd-resolved",
    "echo \"nameserver 8.8.8.8\" > /etc/resolv.conf",
    "systemctl restart unbound",
    "systemctl enable unbound",
    "docker-compose -f ${local.branch_dns_init_dir}/unbound/docker-compose.yml up -d",
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
      create_public_ip   = true
    },
  ]
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
      create_public_ip   = true
    },
  ]
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
    "output/branch1Dns.sh" = local.branch1_unbound_startup
    "output/branch1Vm.sh"  = local.branch1_vm_init
  }
}

resource "local_file" "branch1_files" {
  for_each = local.branch1_files
  filename = each.key
  content  = each.value
}
