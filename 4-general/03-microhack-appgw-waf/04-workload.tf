
####################################################
# workloads
####################################################

module "good_juice_vm" {
  source          = "../../modules/linux"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = local.hub1_prefix
  name            = "good-juice"
  location        = local.hub1_location
  subnet          = module.hub1.subnets["MainSubnet"].id
  custom_data     = base64encode(local.vm_startup_juice)
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.hub1_tags
  depends_on      = [module.hub1]
}

module "bad_juice_vm" {
  source          = "../../modules/linux"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = local.hub1_prefix
  name            = "bad-juice"
  location        = local.hub1_location
  subnet          = module.hub1.subnets["MainSubnet"].id
  custom_data     = base64encode(local.vm_startup_juice)
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.hub1_tags
  depends_on      = [module.hub1]
}
