
locals {
  prefix = var.prefix == "" ? "" : format("%s-", var.prefix)

  firewall_categories_metric = ["AllMetrics"]
  firewall_categories_log = [
    "AzureFirewallApplicationRule",
    "AzureFirewallNetworkRule",
    "AzureFirewallDnsProxy"
  ]
}

# hub
#----------------------------

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

# vpngw
#----------------------------

# s2s

resource "azurerm_vpn_gateway" "this" {
  count               = var.enable_s2s_vpn_gateway ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}vpngw"
  location            = var.location
  virtual_hub_id      = azurerm_virtual_hub.this.id

  bgp_settings {
    asn         = var.bgp_config[0].asn
    peer_weight = var.bgp_config[0].peer_weight
    instance_0_bgp_peering_address {
      custom_ips = var.bgp_config[0].instance_0_custom_ips
    }
    instance_1_bgp_peering_address {
      custom_ips = var.bgp_config[0].instance_1_custom_ips
    }
  }
  timeouts {
    create = "60m"
  }
}

# firewall
#----------------------------

resource "random_id" "azfw" {
  count       = var.security_config[0].create_firewall ? 1 : 0
  byte_length = 4
}

# workspace

resource "azurerm_log_analytics_workspace" "azfw" {
  count               = var.security_config[0].create_firewall ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}azfw-ws-${random_id.azfw[0].hex}"
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# storage account

resource "azurerm_storage_account" "azfw" {
  count                    = var.security_config[0].create_firewall ? 1 : 0
  resource_group_name      = var.resource_group
  name                     = lower(replace("${local.prefix}azfw${random_id.azfw[0].hex}", "-", ""))
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_firewall" "this" {
  count               = var.security_config[0].create_firewall ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}azfw"
  location            = var.location
  sku_tier            = "Standard"
  sku_name            = "AZFW_Hub"
  firewall_policy_id  = var.security_config[0].firewall_policy_id
  virtual_hub {
    virtual_hub_id  = azurerm_virtual_hub.this.id
    public_ip_count = 1
  }
  timeouts {
    create = "60m"
  }
}

# diagnostic setting

resource "azurerm_monitor_diagnostic_setting" "azfw" {
  count                      = var.security_config[0].create_firewall ? 1 : 0
  name                       = "${local.prefix}azfw-diag-${random_id.azfw[0].hex}"
  target_resource_id         = azurerm_firewall.this[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.azfw[0].id
  storage_account_id         = azurerm_storage_account.azfw[0].id

  dynamic "metric" {
    for_each = var.metric_categories_firewall
    content {
      category = metric.value.category
      enabled  = true
    }
  }

  dynamic "enabled_log" {
    for_each = { for k, v in var.log_categories_firewall : k => v if v.enabled }
    content {
      category = enabled_log.value.category
    }
  }
  timeouts {
    create = "60m"
  }
  depends_on = [
    azurerm_log_analytics_workspace.azfw,
    azurerm_storage_account.azfw,
  ]
}

# routing intent
#----------------------------

resource "azurerm_virtual_hub_routing_intent" "this" {
  count          = var.enable_routing_intent ? 1 : 0
  name           = "${local.prefix}hub-ri-policy"
  virtual_hub_id = azurerm_virtual_hub.this.id

  dynamic "routing_policy" {
    for_each = var.routing_policies
    content {
      name         = routing_policy.value.name
      destinations = routing_policy.value.destinations
      next_hop     = azurerm_firewall.this[0].id
    }
  }
}
