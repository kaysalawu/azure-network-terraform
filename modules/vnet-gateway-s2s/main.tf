
####################################################
# log analytics workspace
####################################################

resource "azurerm_log_analytics_workspace" "this" {
  resource_group_name = var.resource_group
  name                = replace("${var.prefix}vpngw-ws", "_", "")
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

####################################################
# ip addresses
####################################################

resource "azurerm_public_ip" "pip0" {
  resource_group_name = var.resource_group
  name                = "${var.prefix}vpngw-pip0"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = [1, 2, 3]
  timeouts {
    create = "60m"
  }
  tags = var.tags
}

resource "azurerm_public_ip" "pip1" {
  resource_group_name = var.resource_group
  name                = "${var.prefix}vpngw-pip1"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = [1, 2, 3]
  timeouts {
    create = "60m"
  }
  tags = var.tags
}

####################################################
# gateway
####################################################

resource "azurerm_virtual_network_gateway" "this" {
  resource_group_name = var.resource_group
  name                = "${var.prefix}vpngw"
  location            = var.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = var.sku
  enable_bgp          = true
  active_active       = true
  tags                = var.tags

  ip_configuration {
    name                          = "ip-config0"
    subnet_id                     = var.subnet_id
    public_ip_address_id          = azurerm_public_ip.pip0.id
    private_ip_address_allocation = "Dynamic"
  }
  ip_configuration {
    name                          = "ip-config1"
    subnet_id                     = var.subnet_id
    public_ip_address_id          = azurerm_public_ip.pip1.id
    private_ip_address_allocation = "Dynamic"
  }

  bgp_settings {
    asn = var.bgp_asn
    peering_addresses {
      ip_configuration_name = "ip-config0"
      apipa_addresses       = try(var.ip_config0_apipa_addresses, ["169.254.21.1"])
    }
    peering_addresses {
      ip_configuration_name = "ip-config1"
      apipa_addresses       = try(var.ip_config1_apipa_addresses, ["169.254.21.5"])
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
  vnetgw_id = "/subscriptions/${data.azurerm_subscription.this.subscription_id}/resourceGroups/${var.resource_group}|${azurerm_virtual_network_gateway.this.name}"
}

data "external" "check_diag_setting" {
  program = ["bash", "${path.module}/../../scripts/check_diag_setting.sh", "${local.vnetgw_id}"]
}*/

resource "azurerm_monitor_diagnostic_setting" "this" {
  #count                      = data.external.check_diag_setting.result["exists"] == "true" ? 0 : 1
  count                      = var.enable_diagnostics && var.create_dashboard ? 1 : 0
  name                       = "${var.prefix}vpngw-diag"
  target_resource_id         = azurerm_virtual_network_gateway.this.id
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
    GATEWAY_NAME = azurerm_virtual_network_gateway.this.name
    GATEWAY_ID   = azurerm_virtual_network_gateway.this.id
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
