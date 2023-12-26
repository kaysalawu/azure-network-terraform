
module "hub1_appgw" {
  source               = "../../modules/appgw"
  resource_group_name  = var.resource_group_name
  location             = var.location
  app_gateway_name     = "appgw"
  virtual_network_name = var.virtual_network_name
  subnet_name          = var.subnet_name
  private_ip_address   = "10.11.0.99"
  public_ip_address_id = azurerm_public_ip.app_gateway.id

  sku = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  backend_address_pools = [
    {
      name         = "server-beap"
      ip_addresses = [module.websocket_server_vm.private_ip_address, ]
    },
  ]

  backend_http_settings = [
    {
      name       = "server-bhs",
      port       = 8080, path = "/",
      probe_name = "server-hp"
    },
  ]

  health_probes = [
    {
      name     = "server-hp",
      host     = local.hub1_host_server,
      protocol = "Http", port = 80,
      path     = "/"
    },
  ]

  http_listeners = [
    {
      name      = "server-http-lsn"
      host_name = local.hub1_host_server
    },
  ]

  request_routing_rules = [
    {
      priority           = 100
      name               = "server-http-rrr"
      http_listener_name = "server-http-lsn"
      rule_type          = "PathBasedRouting"
      url_path_map_name  = "server-upm"
    },
  ]

  url_path_maps = [
    {
      name                               = "server-upm"
      default_backend_http_settings_name = "server-bhs"
      default_backend_address_pool_name  = "server-beap"
      path_rules = [
        {
          name                       = "server-pr"
          paths                      = ["/*"]
          backend_address_pool_name  = "server-beap"
          backend_http_settings_name = "server-bhs"
        },
      ]
    }
  ]

  log_analytics_workspace_name = module.common.log_analytics_workspaces["region1"].name
  identity_ids                 = ["${azurerm_user_assigned_identity.hub1_appgw_http.id}"]

  depends_on = [
    module.hub1,
  ]
}
