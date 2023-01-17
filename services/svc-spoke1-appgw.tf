
resource "azurerm_user_assigned_identity" "spoke1_appgw_http" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.spoke1_location
  name                = "${local.spoke1_prefix}appgw-api"
}

module "application-gateway" {
  source               = "../../modules/appgw"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = local.spoke1_location
  app_gateway_name     = "${local.spoke1_prefix}appgw"
  virtual_network_name = module.spoke1.vnet.name
  subnet_name          = module.spoke1.subnets["${local.spoke1_prefix}appgw"].name
  private_ip_address   = local.spoke1_appgw_addr

  sku = {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  backend_address_pools = [
    {
      name         = "spoke1-branch1-be-addr-pool",
      ip_addresses = [local.spoke1_vm_addr, local.branch1_vm_addr, ]
    },
  ]

  backend_http_settings = [
    {
      name                  = "spoke1-branch1-be-http-set"
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
      name                       = "spoke1-branch1-routing-rule"
      rule_type                  = "Basic"
      http_listener_name         = "http-80"
      backend_address_pool_name  = "spoke1-branch1-be-addr-pool"
      backend_http_settings_name = "spoke1-branch1-be-http-set"
    },
  ]

  #identity_ids = ["${azurerm_user_assigned_identity.spoke1_appgw_http.id}"]
  #log_analytics_workspace_name = azurerm_log_analytics_workspace.analytics_ws.name
  depends_on = [
    azurerm_resource_group.rg
  ]
}
