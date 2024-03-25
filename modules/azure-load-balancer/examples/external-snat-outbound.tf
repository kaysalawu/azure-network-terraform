
###################################################
# external load balancer
###################################################

module "azure_lb_snat" {
  source              = "../../modules/azure-load-balancer"
  resource_group_name = var.resource_group
  location            = var.location
  prefix              = "lab"
  name                = "lb-snat"
  type                = "public"
  lb_sku              = "Standard"

  log_analytics_workspace_name = var.log_analytics_workspace_name

  frontend_ip_configuration = [
    {
      name      = "feip"
      zones     = ["1", "2", "3"]
      subnet_id = var.subnet_id
    },
  ]

  backend_pools = [
    {
      name = "nva"
      interfaces = [{
        ip_configuration_name = "interface"
        network_interface_id  = azure_network_interface.interface.id
      }]
    }
  ]

  outbound_rules = [
    {
      name                           = "ecs-snat"
      frontend_ip_configuration_name = "feip"
      backend_address_pool_name      = "ecs"
      protocol                       = "All"
      allocated_outbound_ports       = 1024
      idle_timeout_in_minutes        = 4
    },
  ]
}
