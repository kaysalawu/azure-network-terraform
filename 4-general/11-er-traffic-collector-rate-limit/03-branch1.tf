
locals {
  branch1_vm_init = templatefile("../../scripts/server.sh", {
    USER_ASSIGNED_ID = azurerm_user_assigned_identity.machine.id
    TARGETS          = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = [
      { count = 10, protocol = "tcp", port = 80, ip = local.hub1_vm_addr, probe = true },
      { count = 10, protocol = "tcp", port = 8080, ip = local.hub1_vm_addr, probe = true },
      { count = 10, protocol = "tcp", port = 8000, ip = local.hub1_vm_addr, probe = true },
      { count = 10, protocol = "tcp", port = 9000, ip = local.hub1_vm_addr, probe = true },

      { count = 10, protocol = "udp", port = 3000, ip = local.hub1_vm_addr, probe = true },
      { count = 10, protocol = "udp", port = 3001, ip = local.hub1_vm_addr, probe = true },
      { count = 10, protocol = "udp", port = 3002, ip = local.hub1_vm_addr, probe = true },
      { count = 10, protocol = "udp", port = 3003, ip = local.hub1_vm_addr, probe = true },
    ]
    TARGETS_HEAVY_TRAFFIC_GEN = [local.hub1_vm_fqdn, ]
    ENABLE_TRAFFIC_GEN        = true
    ENABLE_IPERF3_SERVER      = false
    ENABLE_IPERF3_CLIENT      = true
    IPERF3_SERVER_IP          = local.hub1_vm_addr
  })
}

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

module "branch1_dns" {
  source            = "../../modules/virtual-machine-linux"
  resource_group    = azurerm_resource_group.rg.name
  name              = "${local.branch1_prefix}dns"
  location          = local.branch1_location
  storage_account   = module.common.storage_accounts["region1"]
  custom_data       = base64encode(local.branch_unbound_startup)
  user_assigned_ids = [azurerm_user_assigned_identity.machine.id, ]
  tags              = local.branch1_tags

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

module "branch1_vm" {
  source            = "../../modules/virtual-machine-linux"
  resource_group    = azurerm_resource_group.rg.name
  name              = "${local.branch1_prefix}vm"
  computer_name     = "vm"
  location          = local.branch1_location
  storage_account   = module.common.storage_accounts["region1"]
  dns_servers       = [local.branch1_dns_addr, ]
  custom_data       = base64encode(local.branch1_vm_init)
  user_assigned_ids = [azurerm_user_assigned_identity.machine.id, ]
  tags              = local.branch1_tags

  interfaces = [
    {
      name               = "${local.branch1_prefix}vm-main-nic"
      subnet_id          = module.branch1.subnets["MainSubnet"].id
      private_ip_address = local.branch1_vm_addr
      create_public_ip   = true
    },
  ]
  depends_on = [
    module.branch1
  ]
}

####################################################
# output files
####################################################

locals {
  branch1_files = {
    "output/branch1Vm.sh" = local.branch1_vm_init
  }
}

resource "local_file" "branch1_files" {
  for_each = local.branch1_files
  filename = each.key
  content  = each.value
}
