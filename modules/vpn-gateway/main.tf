
####################################################
# log analytics workspace
####################################################

resource "azurerm_log_analytics_workspace" "this" {
  resource_group_name = var.resource_group
  name                = "${var.prefix}vpngw-ws"
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

####################################################
# gateway
####################################################

resource "azurerm_vpn_gateway" "this" {
  resource_group_name = var.resource_group
  name                = "${var.prefix}vpngw"
  location            = var.location
  virtual_hub_id      = var.virtual_hub_id

  bgp_settings {
    asn         = var.bgp_settings_asn
    peer_weight = var.bgp_settings_peer_weight

    dynamic "instance_0_bgp_peering_address" {
      for_each = var.bgp_settings_instance_0_bgp_peering_address_custom_ips != [] ? [1] : []
      content {
        custom_ips = var.bgp_settings_instance_0_bgp_peering_address_custom_ips
      }
    }

    dynamic "instance_1_bgp_peering_address" {
      for_each = var.bgp_settings_instance_1_bgp_peering_address_custom_ips != [] ? [1] : []
      content {
        custom_ips = var.bgp_settings_instance_1_bgp_peering_address_custom_ips
      }
    }
  }
  timeouts {
    create = "60m"
  }
}

####################################################
# diagnostic setting
####################################################

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = "${var.prefix}vpngw-diag"
  target_resource_id         = azurerm_vpn_gateway.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id
  #log_analytics_destination_type = "Dedicated"

  dynamic "metric" {
    for_each = var.metric_categories
    content {
      category = metric.value.category
      enabled  = true
    }
  }

  dynamic "enabled_log" {
    for_each = { for k, v in var.log_categories : k => v if v.enabled }
    content {
      category = enabled_log.value.category
    }
  }
  timeouts {
    create = "60m"
  }
}

####################################################
# dashboard
####################################################

locals {
  dashboard_vars = {
    GATEWAY_NAME = azurerm_vpn_gateway.this.name
    GATEWAY_ID   = azurerm_vpn_gateway.this.id
    LOCATION     = var.location
  }
  dashboard_properties = templatefile("${path.module}/templates/dashboard.json", local.dashboard_vars)
}

resource "azurerm_portal_dashboard" "this" {
  count                = var.create_dashboard ? 1 : 0
  name                 = "${var.prefix}vpngw-db"
  resource_group_name  = var.resource_group
  location             = var.location
  tags                 = var.tags
  dashboard_properties = local.dashboard_properties
}
