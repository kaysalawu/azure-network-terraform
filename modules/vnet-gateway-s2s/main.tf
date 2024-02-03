
####################################################
# log analytics workspace
####################################################

data "azurerm_log_analytics_workspace" "this" {
  count               = var.log_analytics_workspace_name != null ? 1 : 0
  name                = var.log_analytics_workspace_name
  resource_group_name = var.resource_group
}

####################################################
# ip addresses
####################################################

data "azurerm_public_ip" "this" {
  for_each            = { for i in var.ip_configuration : i.name => i if i.public_ip_address_name != null }
  resource_group_name = var.resource_group
  name                = each.value.public_ip_address_name
}

resource "azurerm_public_ip" "this" {
  for_each            = { for i in var.ip_configuration : i.name => i if i.public_ip_address_name == null }
  resource_group_name = var.resource_group
  name                = each.value.public_ip_address_name
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
  enable_bgp          = var.enable_bgp
  active_active       = length(var.ip_configuration) > 1 ? true : var.active_active
  tags                = var.tags

  dynamic "ip_configuration" {
    for_each = { for i in var.ip_configuration : i.name => i if i.public_ip_address_name != null }
    content {
      name                          = ip_configuration.value["name"]
      subnet_id                     = ip_configuration.value["subnet_id"]
      public_ip_address_id          = data.azurerm_public_ip.this[ip_configuration.key].id != null ? data.azurerm_public_ip.this[ip_configuration.key].id : azurerm_public_ip.this[ip_configuration.key].id
      private_ip_address_allocation = ip_configuration.value["private_ip_address_allocation"]
    }
  }

  bgp_settings {
    asn = var.bgp_asn

    dynamic "peering_addresses" {
      for_each = { for i in var.ip_configuration : i.name => i if i.apipa_addresses != null }
      content {
        ip_configuration_name = peering_addresses.value["name"]
        apipa_addresses       = peering_addresses.value["apipa_addresses"]
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
  count                      = var.log_analytics_workspace_name != null ? 1 : 0
  name                       = "${var.prefix}vpngw-diag"
  target_resource_id         = azurerm_virtual_network_gateway.this.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.this[0].id

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
  count                = var.log_analytics_workspace_name != null ? 1 : 0
  name                 = "${var.prefix}vpngw-db"
  resource_group_name  = var.resource_group
  location             = var.location
  tags                 = var.tags
  dashboard_properties = local.dashboard_properties
}
