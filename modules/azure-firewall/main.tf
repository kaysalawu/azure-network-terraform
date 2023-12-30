
####################################################
# workspace
####################################################

resource "azurerm_log_analytics_workspace" "this" {
  resource_group_name = var.resource_group
  name                = "${var.prefix}azfw-ws"
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

####################################################
# ip addresses
####################################################

# firewall

resource "azurerm_public_ip" "pip" {
  resource_group_name = var.resource_group
  name                = "${var.prefix}azfw-pip"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags
  timeouts {
    create = "60m"
  }
}

# firewall management

resource "azurerm_public_ip" "mgt_pip" {
  resource_group_name = var.resource_group
  name                = "${var.prefix}azfw-mgt-pip"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags
  timeouts {
    create = "60m"
  }
}

####################################################
# firewall
####################################################

resource "azurerm_firewall" "this" {
  resource_group_name = var.resource_group
  name                = "${var.prefix}azfw"
  location            = var.location
  sku_tier            = var.sku_tier
  sku_name            = var.sku_name
  firewall_policy_id  = var.firewall_policy_id
  tags                = var.tags

  dynamic "virtual_hub" {
    for_each = var.sku_name == "AZFW_Hub" ? [1] : []
    content {
      virtual_hub_id  = var.virtual_hub_id
      public_ip_count = var.virtual_hub_public_ip_count
    }
  }

  dynamic "ip_configuration" {
    for_each = var.sku_name == "AZFW_VNet" ? [1] : []
    content {
      name                 = "ip-config"
      subnet_id            = var.subnet_id
      public_ip_address_id = azurerm_public_ip.pip.id
    }
  }
  dynamic "management_ip_configuration" {
    for_each = var.sku_name == "AZFW_VNet" ? [1] : []
    content {
      name                 = "mgmt-ip-config"
      subnet_id            = var.mgt_subnet_id
      public_ip_address_id = azurerm_public_ip.mgt_pip.id
    }
  }

  timeouts {
    create = "60m"
  }

  lifecycle {
    ignore_changes = [
      ip_configuration,
      management_ip_configuration,
    ]
  }

  depends_on = [
    azurerm_public_ip.mgt_pip,
    azurerm_public_ip.pip,
  ]
}

####################################################
# diagnostic setting
####################################################

resource "azurerm_monitor_diagnostic_setting" "azfw" {
  name                           = "${var.prefix}azfw-diag"
  target_resource_id             = azurerm_firewall.this.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.this.id
  log_analytics_destination_type = "Dedicated"

  metric {

    category = "AllMetrics"
    enabled  = true

  }

  dynamic "enabled_log" {
    for_each = var.log_categories_firewall
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
    FIREWALL_NAME = azurerm_firewall.this.name
    FIREWALL_ID   = azurerm_firewall.this.id
    LOCATION      = var.location
  }
  dashboard_properties = templatefile("${path.module}/templates/dashboard.json", local.dashboard_vars)
}

resource "azurerm_portal_dashboard" "this" {
  count                = var.enable_diagnostics && var.create_dashboard ? 1 : 0
  name                 = "${var.prefix}azfw-db"
  resource_group_name  = var.resource_group
  location             = var.location
  tags                 = var.tags
  dashboard_properties = local.dashboard_properties
}
