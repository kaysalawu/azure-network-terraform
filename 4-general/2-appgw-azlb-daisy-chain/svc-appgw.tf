
resource "azurerm_user_assigned_identity" "hub1_appgw_http" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.hub1_location
  name                = "${local.hub1_prefix}appgw-api"
}

module "hub1_appgw" {
  source               = "../../modules/appgw"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = local.hub1_location
  app_gateway_name     = "${local.hub1_prefix}appgw"
  virtual_network_name = module.hub1.vnet.name
  subnet_name          = module.hub1.subnets["AppGatewaySubnet"].name
  private_ip_address   = local.hub1_appgw_addr

  sku = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  backend_address_pools = [
    {
      name         = "wdp-be-addr-pool",
      ip_addresses = [local.hub1_nva_ilb_addr, ]
    },
  ]

  backend_http_settings = [
    {
      name                  = "wdp-be-http-set"
      cookie_based_affinity = "Disabled"
      path                  = "/"
      enable_https          = false
      request_timeout       = 30
      connection_draining = {
        enable_connection_draining = true
        drain_timeout_sec          = 300

      }
    },
  ]

  http_listeners = [
    { name = "http-80", host_name = null },
    #{ name = "https-443", host_name = null }
  ]

  request_routing_rules = [
    {
      priority                   = 100
      name                       = "wdp-routing-rule"
      rule_type                  = "Basic"
      http_listener_name         = "http-80"
      backend_address_pool_name  = "wdp-be-addr-pool"
      backend_http_settings_name = "wdp-be-http-set"
    },
  ]

  #identity_ids = ["${azurerm_user_assigned_identity.hub1_appgw_http.id}"]
  #log_analytics_workspace_name = azurerm_log_analytics_workspace.analytics_ws.name
  depends_on = [
    azurerm_resource_group.rg,
    module.hub1
  ]
}
