
####################################################
# log analytics workspace
####################################################

resource "azurerm_log_analytics_workspace" "this" {
  resource_group_name = var.resource_group
  name                = replace("${var.prefix}ergw-ws", "_", "")
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

####################################################
# ip addresses
####################################################

resource "azurerm_public_ip" "this" {
  resource_group_name = var.resource_group
  name                = "${var.prefix}ergw-pip0"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags
  timeouts {
    create = "60m"
  }
}

####################################################
# gateway
####################################################

resource "azurerm_virtual_network_gateway" "this" {
  resource_group_name = var.resource_group
  name                = "${var.prefix}ergw"
  location            = var.location
  type                = "ExpressRoute"
  vpn_type            = "RouteBased"
  sku                 = var.sku
  enable_bgp          = true
  active_active       = false

  ip_configuration {
    name                          = "ip-config"
    subnet_id                     = var.subnet_id
    public_ip_address_id          = azurerm_public_ip.this.id
    private_ip_address_allocation = "Dynamic"
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
  vnetgw_id = "/subscriptions/${data.azurerm_subscription.this.subscription_id}/resourceGroups/${var.resource_group}|${azurerm_virtual_network_gateway.this.name}"
}

data "external" "check_diag_setting" {
  program = ["bash", "${path.module}/../../scripts/check_diag_setting.sh", "${local.vnetgw_id}"]
}*/

resource "azurerm_monitor_diagnostic_setting" "this" {
  #count                      = data.external.check_diag_setting.result["exists"] == "true" ? 0 : 1
  count                      = var.enable_diagnostics && var.create_dashboard ? 1 : 0
  name                       = "${var.prefix}ergw-diag"
  target_resource_id         = azurerm_virtual_network_gateway.this.id
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
    GATEWAY_NAME = azurerm_virtual_network_gateway.this.name
    GATEWAY_ID   = azurerm_virtual_network_gateway.this.id
    LOCATION     = var.location
  }
  dashboard_properties = templatefile("${path.module}/templates/dashboard.json", local.dashboard_vars)
}

resource "azurerm_portal_dashboard" "this" {
  count                = var.enable_diagnostics && var.create_dashboard ? 1 : 0
  name                 = "${var.prefix}ergw-db"
  resource_group_name  = var.resource_group
  location             = var.location
  tags                 = var.tags
  dashboard_properties = local.dashboard_properties
}
