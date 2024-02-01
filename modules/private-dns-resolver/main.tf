
####################################################
# dns resolver
####################################################

resource "azurerm_private_dns_resolver" "this" {
  resource_group_name = var.resource_group
  name                = "${var.prefix}dns-resolver"
  location            = var.location
  virtual_network_id  = var.virtual_network_id
  timeouts {
    create = "60m"
  }
  tags = var.tags
}

####################################################
# endpoints
####################################################

# inbound

resource "azurerm_private_dns_resolver_inbound_endpoint" "this" {
  name                    = "${var.prefix}dns-in"
  private_dns_resolver_id = azurerm_private_dns_resolver.this.id
  location                = var.location
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = var.private_dns_inbound_subnet_id
  }
  timeouts {
    create = "60m"
  }
}

# outbound

resource "azurerm_private_dns_resolver_outbound_endpoint" "this" {
  name                    = "${var.prefix}dns-out"
  private_dns_resolver_id = azurerm_private_dns_resolver.this.id
  location                = var.location
  subnet_id               = var.private_dns_outbound_subnet_id
  timeouts {
    create = "60m"
  }
}

####################################################
# ruleset
####################################################

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "this" {
  resource_group_name = var.resource_group
  name                = "${var.prefix}ruleset"
  location            = var.location

  private_dns_resolver_outbound_endpoint_ids = [azurerm_private_dns_resolver_outbound_endpoint.this.id]
}

####################################################
# dns resolver links
####################################################

# local

resource "azurerm_private_dns_resolver_virtual_network_link" "this" {
  name                      = "${var.prefix}vnet-link"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.this.id
  virtual_network_id        = var.virtual_network_id
}

# external

resource "azurerm_private_dns_resolver_virtual_network_link" "external" {
  for_each                  = { for k, v in var.private_dns_ruleset_linked_external_vnets : k => v }
  name                      = "${var.prefix}${each.key}-vnet-link"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.this.id
  virtual_network_id        = each.value
}

resource "azurerm_private_dns_resolver_forwarding_rule" "this" {
  for_each                  = { for k, v in var.ruleset_dns_forwarding_rules : k => v }
  name                      = "${var.prefix}${each.key}-rule"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.this.id
  domain_name               = "${each.value.domain}."
  enabled                   = true

  dynamic "target_dns_servers" {
    for_each = each.value.target_dns_servers
    content {
      ip_address = target_dns_servers.value.ip_address
      port       = target_dns_servers.value.port
    }
  }
}

####################################################
# dashboard
####################################################

locals {
  dashboard_vars = {
    PRIVATE_DNS_RESOLVER_ID = azurerm_private_dns_resolver.this.id
  }
  dashboard_properties = templatefile("${path.module}/templates/dashboard.json", local.dashboard_vars)
}

resource "azurerm_portal_dashboard" "this" {
  count                = var.log_analytics_workspace_name != null ? 1 : 0
  name                 = "${var.prefix}private-dns-resolver"
  resource_group_name  = var.resource_group
  location             = var.location
  tags                 = var.tags
  dashboard_properties = local.dashboard_properties
}

