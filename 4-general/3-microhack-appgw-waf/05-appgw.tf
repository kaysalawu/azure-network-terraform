
####################################################
# identity
####################################################

resource "azurerm_user_assigned_identity" "hub1_appgw_http" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.hub1_location
  name                = "${local.hub1_prefix}appgw-api"
}

####################################################
# app gateway
####################################################

module "hub1_appgw" {
  source                 = "../../modules/application-gateway"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = local.hub1_location
  app_gateway_name       = "${local.hub1_prefix}appgw"
  virtual_network_name   = module.hub1.vnet.name
  subnet_name            = module.hub1.subnets["AppGatewaySubnet"].name
  private_ip_address     = local.hub1_appgw_addr
  public_ip_address_name = azurerm_public_ip.hub1_appgw_pip.name

  sku = {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  backend_address_pools = [
    { name = "good-juice-beap", ip_addresses = [module.good_juice_vm.private_ip_address, ] },
    { name = "bad-juice-beap", ip_addresses = [module.bad_juice_vm.private_ip_address, ] },
  ]

  backend_http_settings = [
    { name = "good-juice-bhs", port = 3000, path = "/", probe_name = "good-juice-hp" },
    { name = "bad-juice-bhs", port = 3000, path = "/", probe_name = "bad-juice-hp" },
  ]

  health_probes = [
    { name = "good-juice-hp", host = local.hub1_host_good_juice, protocol = "Http", port = 3000, path = "/" },
    { name = "bad-juice-hp", host = local.hub1_host_bad_juice, protocol = "Http", port = 3000, path = "/" },
  ]

  http_listeners = [
    {
      name      = "good-juice-http-lsn"
      host_name = local.hub1_host_good_juice
      #firewall_policy_id = azurerm_web_application_firewall_policy.hub1_appgw.id
    },
    {
      name      = "bad-juice-http-lsn"
      host_name = local.hub1_host_bad_juice
    },
  ]

  request_routing_rules = [
    {
      priority           = 100
      name               = "good-juice-http-rrr"
      http_listener_name = "good-juice-http-lsn"
      rule_type          = "PathBasedRouting"
      url_path_map_name  = "good-juice-upm"
    },
    {
      priority                   = 200
      name                       = "bad-juice-http-rrr"
      http_listener_name         = "bad-juice-http-lsn"
      backend_address_pool_name  = "bad-juice-beap"
      backend_http_settings_name = "bad-juice-bhs"
      rule_type                  = "Basic"
    },
  ]

  url_path_maps = [
    {
      name                               = "good-juice-upm"
      default_backend_http_settings_name = "good-juice-bhs"
      default_backend_address_pool_name  = "good-juice-beap"
      path_rules = [
        {
          name                       = "good-juice-pr"
          paths                      = ["/*"]
          backend_address_pool_name  = "good-juice-beap"
          backend_http_settings_name = "good-juice-bhs"
          firewall_policy_id         = azurerm_web_application_firewall_policy.hub1_appgw.id
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
