
####################################################
# workloads
####################################################

module "websocket_client_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-WebSocClient"
  computer_name   = "WebSocClient"
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.vm_websocket_client_init.cloud_config)
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

module "websocket_server_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-WebSocServer"
  computer_name   = "WebSocServer"
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.vm_websocket_server_init.cloud_config)
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

