
####################################################
# workloads
####################################################

module "websocket_client_vm" {
  source          = "../../modules/linux"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = local.hub1_prefix
  name            = "client"
  location        = local.hub1_location
  subnet          = module.hub1.subnets["MainSubnet"].id
  custom_data     = base64encode(module.vm_websocket_client_init.cloud_config)
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.hub1_tags
  depends_on      = [module.hub1]
}

module "websocket_server_vm" {
  source          = "../../modules/linux"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = local.hub1_prefix
  name            = "server"
  location        = local.hub1_location
  subnet          = module.hub1.subnets["MainSubnet"].id
  custom_data     = base64encode(module.vm_websocket_server_init.cloud_config)
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.hub1_tags
  depends_on      = [module.hub1]
}
