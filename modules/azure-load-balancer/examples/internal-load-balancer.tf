
module "ilb_trust" {
  source              = "../../modules/azure-load-balancer"
  resource_group_name = var.resource_group
  location            = var.location
  prefix              = "lab"
  name                = "ilb-trust"
  type                = "private"
  lb_sku              = "Standard"

  log_analytics_workspace_name = var.log_analytics_workspace_name

  frontend_ip_configuration = [
    {
      name                          = "nva"
      zones                         = ["1", "2", "3"]
      subnet_id                     = azure_subnet.trust.id
      private_ip_address            = var.private_ip_address
      private_ip_address_allocation = "Static"
    }
  ]

  probes = [
    { name = "ssh", protocol = "Tcp", port = "443", request_path = "" },
  ]

  backend_pools = [
    {
      name = "nva"
      interfaces = [{
        ip_configuration_name = "nva-trust-ip"
        network_interface_id  = azure_network_interface.trust.id
      }]
    }
  ]

  lb_rules = [
    {
      name                           = "nva-ha"
      protocol                       = "All"
      frontend_port                  = "0"
      backend_port                   = "0"
      frontend_ip_configuration_name = "nva"
      backend_address_pool_name      = ["nva", ]
      probe_name                     = "ssh"
    },
  ]
}
