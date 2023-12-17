
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
      name = "wdp-beap",
      ip_addresses = [
        module.spoke1_be1.private_ip_address,
        module.spoke1_be2.private_ip_address
      ]
    },
    {
      name = "pace-beap",
      ip_addresses = [
        module.spoke1_be1.private_ip_address,
        module.spoke1_be2.private_ip_address
      ]
    },
  ]

  backend_http_settings = [
    {
      name                  = "wdp-bhs"
      cookie_based_affinity = "Disabled"
      protocol              = "Http"
      port                  = 8080
      path                  = "/"
      probe_name            = "wdp-hp"
      enable_https          = false
      request_timeout       = 30
      connection_draining = {
        enable_connection_draining = true
        drain_timeout_sec          = 300

      }
    },
    {
      name                  = "pace-bhs"
      cookie_based_affinity = "Disabled"
      protocol              = "Http"
      port                  = 8081
      path                  = "/"
      probe_name            = "pace-hp"
      enable_https          = false
      request_timeout       = 30
      connection_draining = {
        enable_connection_draining = true
        drain_timeout_sec          = 300

      }
    },
  ]

  health_probes = [
    {
      name                = "wdp-hp"
      host                = "healthz.az.corp"
      protocol            = "Http"
      port                = 8080
      request_path        = "/healthz"
      interval            = 30
      timeout             = 30
      unhealthy_threshold = 3
    },
    {
      name                = "pace-hp"
      host                = "healthz.az.corp"
      port                = 8081
      protocol            = "Http"
      request_path        = "/healthz"
      interval            = 30
      timeout             = 30
      unhealthy_threshold = 3
    },
  ]

  http_listeners = [
    { name = "wdp-lsn", host_name = "wdp.we.az.corp" },
    { name = "pace-lsn", host_name = "pace.we.az.corp" },
    #{ name = "https-443", host_name = null }
  ]

  request_routing_rules = [
    {
      priority                   = 100
      name                       = "wdp-rrr"
      rule_type                  = "Basic"
      http_listener_name         = "wdp-lsn"
      backend_address_pool_name  = "wdp-beap"
      backend_http_settings_name = "wdp-bhs"
    },
    {
      priority                   = 200
      name                       = "pace-rrr"
      rule_type                  = "Basic"
      http_listener_name         = "pace-lsn"
      backend_address_pool_name  = "pace-beap"
      backend_http_settings_name = "pace-bhs"
    },
  ]

  #identity_ids = ["${azurerm_user_assigned_identity.hub1_appgw_http.id}"]
  #log_analytics_workspace_name = azurerm_log_analytics_workspace.analytics_ws.name
  depends_on = [
    azurerm_resource_group.rg,
    module.hub1
  ]
}
