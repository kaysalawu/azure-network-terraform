
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

  firewall_policy_id = var.config_security.firewall_policy_id

  depends_on = [
    module.vpngw,
  ]
}

####################################################
# routing intent
####################################################

resource "azurerm_virtual_hub_routing_intent" "this" {
  count          = var.config_security.enable_routing_intent ? 1 : 0
  name           = "${local.prefix}hub-ri-policy"
  virtual_hub_id = azurerm_virtual_hub.this.id

  dynamic "routing_policy" {
    for_each = var.config_security.routing_policies["internet"] ? [1] : []
    content {
      name         = "Internet"
      destinations = ["Internet"]
      next_hop     = module.azfw[0].firewall.id
    }
  }

  dynamic "routing_policy" {
    for_each = var.config_security.routing_policies["private_traffic"] ? [1] : []
    content {
      name         = "PrivateTraffic"
      destinations = ["PrivateTraffic"]
      next_hop     = module.azfw[0].firewall.id
    }
  }
}

# resource "azapi_resource" "hub_route_intent" {
#   count     = var.config_security.enable_routing_intent ? 1 : 0
#   name      = "${local.prefix}hub-ri-policy"
#   parent_id = azurerm_virtual_hub.this.id
#   type      = "Microsoft.Network/virtualHubs/routingIntent@2022-09-01"

#   body = jsonencode({
#     properties = {
#       routingPolicies = [for routing_policy in var.config_security.routing_policies : {
#         name         = routing_policy.name
#         destinations = routing_policy.destinations
#         nextHop      = module.azfw[0].firewall.id
#       }]
#     }
#   })
# }

####################################################
# static routes
####################################################

resource "time_sleep" "this" {
  create_duration = "60s"
  depends_on = [
    azurerm_virtual_hub.this,
    azurerm_virtual_hub_routing_intent.this,
  ]
}

resource "azurerm_virtual_hub_route_table_route" "this" {
  for_each          = var.config_security.enable_routing_intent ? var.config_security.routing_policies.additional_prefixes : {}
  route_table_id    = data.azurerm_virtual_hub_route_table.default.id
  name              = each.key
  destinations_type = "CIDR"
  destinations      = each.value
  next_hop_type     = "ResourceId"
  next_hop          = module.azfw[0].firewall.id
  depends_on = [
    time_sleep.this,
  ]
}
