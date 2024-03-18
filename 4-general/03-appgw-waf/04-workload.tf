
####################################################
# workloads
####################################################

module "good_juice_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-goodJuice"
  computer_name   = "goodJuice"
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.vm_startup_juice)
  tags            = local.hub1_tags

  interfaces = [
    {
      name               = "${local.spoke1_prefix}vm-main-nic"
      subnet_id          = module.hub1.subnets["MainSubnet"].id
      private_ip_address = local.spoke1_vm_addr
    },
  ]
  depends_on = [
    module.hub1
  ]
}

module "bad_juice_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-badJuice"
  computer_name   = "badJuice"
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.vm_startup_juice)
  tags            = local.hub1_tags

  interfaces = [
    {
      name               = "${local.spoke1_prefix}vm-main-nic"
      subnet_id          = module.hub1.subnets["MainSubnet"].id
      private_ip_address = local.spoke1_vm_addr
    },
  ]
  depends_on = [
    module.hub1
  ]
}
