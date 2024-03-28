
###################################################
# external load balancer
###################################################

module "azure_lb_snat" {
  source              = "../../modules/azure-load-balancer"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.hub_location
  prefix              = trimsuffix(local.hub_prefix, "-")
  name                = "lb-snat"
  type                = "public"
  lb_sku              = "Standard"

  log_analytics_workspace_name = module.common.log_analytics_workspaces["region1"].name

  frontend_ip_configuration = [
    {
      name      = "feip"
      zones     = ["1", "2", "3"]
      subnet_id = module.hub.subnets["PublicSubnet"].id
    },
  ]

  backend_pools = [
    {
      name = "hub"
      interfaces = [
        # {
        #   ip_configuration_name = module.hub_cgs.interface_names["${local.hub_prefix}cgs-prod-nic"]
        #   network_interface_id  = module.hub_cgs.interface_ids["${local.hub_prefix}cgs-prod-nic"]
        # },
        # {
        #   ip_configuration_name = module.hub_server1_vm.interface_names["${local.hub_prefix}server1-nic"]
        #   network_interface_id  = module.hub_server1_vm.interface_ids["${local.hub_prefix}server1-nic"]
        # },
        # {
        #   ip_configuration_name = module.hub_server2_vm.interface_names["${local.hub_prefix}test-nic"]
        #   network_interface_id  = module.hub_server2_vm.interface_ids["${local.hub_prefix}test-nic"]
        # }
      ]
    }
  ]

  outbound_rules = [
    {
      name                           = "hub-snat"
      frontend_ip_configuration_name = "feip"
      backend_address_pool_name      = "hub"
      protocol                       = "All"
      allocated_outbound_ports       = 1024
      idle_timeout_in_minutes        = 4
    },
  ]
}
