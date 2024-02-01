
####################################################
# log analytics workspace
####################################################

# resource "azurerm_log_analytics_workspace" "this" {
#   resource_group_name = var.resource_group
#   name                = replace("${var.prefix}vpngw-ws", "_", "")
#   location            = var.location
#   sku                 = "PerGB2018"
#   retention_in_days   = 30
#   tags                = var.tags
# }

####################################################
# gateway
####################################################

resource "azurerm_vpn_gateway" "this" {
  resource_group_name = var.resource_group
  name                = "${var.prefix}vpngw"
  location            = var.location
  virtual_hub_id      = var.virtual_hub_id
  scale_unit          = var.scale_unit
  tags                = var.tags

  dynamic "bgp_settings" {
    for_each = var.bgp_settings != {} ? [1] : []
    content {
      asn         = var.bgp_settings.asn
      peer_weight = var.bgp_settings.peer_weight

      dynamic "instance_0_bgp_peering_address" {
        for_each = var.bgp_settings.instance_0_bgp_peering_address_custom_ips != [] ? [1] : []
        content {
          custom_ips = var.bgp_settings.instance_0_bgp_peering_address_custom_ips
        }
      }

      dynamic "instance_1_bgp_peering_address" {
        for_each = var.bgp_settings.instance_1_bgp_peering_address_custom_ips != [] ? [1] : []
        content {
          custom_ips = var.bgp_settings.instance_1_bgp_peering_address_custom_ips
        }
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

# subscription id
/*
data "azurerm_subscription" "this" {}

locals {
  vpngw_id = "/subscriptions/${data.azurerm_subscription.this.subscription_id}/resourceGroups/${var.resource_group}|${azurerm_vpn_gateway.this.name}"
}

data "external" "check_diag_setting" {
  program = ["bash", "${path.module}/../../scripts/check_diag_setting.sh", "${local.vpngw_id}"]
}*/

resource "azurerm_monitor_diagnostic_setting" "this" {
  #count                      = data.external.check_diag_setting.result == "true" ? 1 : 0
  count                      = var.enable_diagnostics && var.create_dashboard ? 1 : 0
  name                       = "${var.prefix}vpngw-diag"
  target_resource_id         = azurerm_vpn_gateway.this.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  metric {
    category = "AllMetrics"
    enabled  = true
  }

  dynamic "enabled_log" {
    for_each = var.log_categories
    content {
      category = enabled_log.value
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
  count                = var.enable_diagnostics && var.create_dashboard ? 1 : 0
  name                 = "${var.prefix}vpngw-db"
  resource_group_name  = var.resource_group
  location             = var.location
  tags                 = var.tags
  dashboard_properties = local.dashboard_properties
}
