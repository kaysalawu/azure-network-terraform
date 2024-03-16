
####################################################
# app servers
####################################################

module "appsrv1_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.ecs_appsrv1_hostname}"
  computer_name   = local.ecs_appsrv1_hostname
  location        = local.ecs_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.vm_startup)
  tags            = local.ecs_tags

  interfaces = [
    {
      name               = "${local.ecs_prefix}vm-prod-nic"
      subnet_id          = module.ecs.subnets["ProductionSubnet"].id
      private_ip_address = local.ecs_appsrv1_addr
      create_public_ip   = true
    },
  ]
  depends_on = [
    module.ecs
  ]
}

# module "appsrv2_vm" {
#   source          = "../../modules/virtual-machine-linux"
#   resource_group  = azurerm_resource_group.rg.name
#   name            = "${local.prefix}-${local.ecs_appsrv2_hostname}"
#   computer_name   = local.ecs_appsrv2_hostname
#   location        = local.ecs_location
#   storage_account = module.common.storage_accounts["region1"]
#   custom_data     = base64encode(local.vm_startup)
#   tags            = local.ecs_tags

#   interfaces = [
#     {
#       name               = "${local.ecs_prefix}vm-prod-nic"
#       subnet_id          = module.ecs.subnets["ProductionSubnet"].id
#       private_ip_address = local.ecs_appsrv2_addr
#       create_public_ip   = true
#     },
#   ]
#   depends_on = [
#     module.ecs
#   ]
# }
