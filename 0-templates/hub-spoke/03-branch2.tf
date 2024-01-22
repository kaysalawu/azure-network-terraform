
locals {
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
# workload
####################################################

module "branch2_vm" {
  source           = "../../modules/linux"
  resource_group   = azurerm_resource_group.rg.name
  prefix           = local.branch2_prefix
  name             = "vm"
  location         = local.branch2_location
  subnet           = module.branch2.subnets["MainSubnet"].id
  private_ip       = local.branch2_vm_addr
  enable_public_ip = true
  source_image     = "ubuntu-20"
  dns_servers      = [local.branch2_dns_addr, ]
  custom_data      = base64encode(local.branch2_vm_init)
  storage_account  = module.common.storage_accounts["region1"]
  delay_creation   = "60s"
  tags             = local.branch2_tags

  depends_on = [
    module.branch2,
    module.branch2_dns,
  ]
}

####################################################
# udr
####################################################

# main

module "branch2_udr_main" {
  source                        = "../../modules/route"
  resource_group                = azurerm_resource_group.rg.name
  prefix                        = "${local.branch2_prefix}main"
  location                      = local.branch2_location
  subnet_id                     = module.branch2.subnets["MainSubnet"].id
  next_hop_type                 = "VirtualAppliance"
  next_hop_in_ip_address        = local.branch2_nva_trust_addr
  destinations                  = local.private_prefixes_map
  delay_creation                = "90s"
  disable_bgp_route_propagation = true
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
    "output/branch2-vm.sh" = local.branch2_vm_init
  }
}

resource "local_file" "branch1_files" {
  for_each = local.branch1_files
  filename = each.key
  content  = each.value
}
