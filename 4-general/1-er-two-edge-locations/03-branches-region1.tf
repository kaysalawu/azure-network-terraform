
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
    #nat_gateway_subnet_names = ["${local.branch1_prefix}main", ]
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
# output files
####################################################

locals {
  branch1_files = {}
}

resource "local_file" "branch1_files" {
  for_each = local.branch1_files
  filename = each.key
  content  = each.value
}
