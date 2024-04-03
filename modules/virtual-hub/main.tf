
locals {
  prefix = var.prefix == "" ? "" : format("%s-", var.prefix)

  firewall_categories_metric = ["AllMetrics"]
  firewall_categories_log = [
    "AzureFirewallApplicationRule",
    "AzureFirewallNetworkRule",
    "AzureFirewallDnsProxy"
  ]
}

####################################################
# hub
####################################################

resource "azurerm_virtual_hub" "this" {
  resource_group_name    = var.resource_group
  name                   = "${local.prefix}hub"
  location               = var.location
  virtual_wan_id         = var.virtual_wan_id
  address_prefix         = var.address_prefix
  sku                    = var.sku
  hub_routing_preference = var.hub_routing_preference
  timeouts {
    create = "60m"
  }
}

data "azurerm_virtual_hub_route_table" "default" {
  resource_group_name = var.resource_group
  name                = "defaultRouteTable"
  virtual_hub_name    = azurerm_virtual_hub.this.name
  depends_on          = [azurerm_virtual_hub.this, ]
}

####################################################
# s2s vpn gateway
####################################################

module "vpngw" {
  count          = var.s2s_vpn_gateway.enable ? 1 : 0
  source         = "../../modules/vpn-gateway"
  resource_group = var.resource_group
  prefix         = local.prefix
  location       = var.location
  virtual_hub_id = azurerm_virtual_hub.this.id
  bgp_settings   = var.s2s_vpn_gateway.bgp_settings

  log_analytics_workspace_name = var.enable_diagnostics ? var.log_analytics_workspace_name : null
}

####################################################
# express route gateway
####################################################

module "ergw" {
  count          = var.express_route_gateway.enable ? 1 : 0
  source         = "../../modules/express-route-gateway"
  resource_group = var.resource_group
  prefix         = local.prefix
  location       = var.location
  virtual_hub_id = azurerm_virtual_hub.this.id

  log_analytics_workspace_name = var.enable_diagnostics ? var.log_analytics_workspace_name : null
}

####################################################
# point-to-site gateway
####################################################

module "p2sgw" {
  count          = var.p2s_vpn_gateway.enable ? 1 : 0
  source         = "../../modules/point-to-site-gateway"
  resource_group = var.resource_group
  prefix         = local.prefix
  location       = var.location
  virtual_hub_id = azurerm_virtual_hub.this.id

  custom_route_address_prefixes = try(var.p2s_vpn_gateway.custom_route_address_prefixes, [])

  vpn_client_configuration = {
    address_space = try(var.p2s_vpn_gateway.vpn_client_configuration.address_space, ["172.16.0.0/24"])
    clients       = try(var.p2s_vpn_gateway.vpn_client_configuration.clients, [])
  }
  log_analytics_workspace_name = var.enable_diagnostics ? var.log_analytics_workspace_name : null
}

####################################################
# firewall
####################################################

module "azfw" {
  count          = var.config_security.create_firewall ? 1 : 0
  source         = "../../modules/azure-firewall"
  resource_group = var.resource_group
  prefix         = local.prefix
  env            = var.env
  location       = var.location
  virtual_hub_id = azurerm_virtual_hub.this.id
  sku_name       = "AZFW_Hub"
  tags           = var.tags

  firewall_policy_id           = var.config_security.firewall_policy_id
  log_analytics_workspace_name = var.enable_diagnostics ? var.log_analytics_workspace_name : null

  depends_on = [
    module.vpngw,
  ]
}

####################################################
# routing intent
####################################################

resource "azurerm_virtual_hub_routing_intent" "this" {
  count          = length(var.config_security.routing_policies) > 0 ? 1 : 0
  name           = "${local.prefix}hub-ri-policy"
  virtual_hub_id = azurerm_virtual_hub.this.id

  dynamic "routing_policy" {
    for_each = var.config_security.routing_policies
    content {
      name         = routing_policy.value.name
      destinations = routing_policy.value.destinations
      next_hop     = module.azfw[0].firewall.id
    }
  }
}
