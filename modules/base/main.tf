
locals {
  prefix = var.prefix == "" ? "" : format("%s-", var.prefix)
  nat_gateway_subnet_ids = {
    for k, v in var.vnet_config[0].subnets : k => azurerm_subnet.this[k].id
    if contains(var.vnet_config[0].nat_gateway_subnet_names, k)
  }
}

# vnet
#----------------------------

resource "azurerm_virtual_network" "this" {
  resource_group_name = var.resource_group
  name                = "${local.prefix}vnet"
  address_space       = var.vnet_config[0].address_space
  location            = var.location
  tags                = var.tags
}

# subnets
#----------------------------

resource "azurerm_subnet" "this" {
  for_each             = var.vnet_config[0].subnets
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.this.name
  name                 = each.key
  address_prefixes     = each.value.address_prefixes

  dynamic "delegation" {
    for_each = [for d in var.delegation : d if contains(try(each.value.delegate, []), d.name)]
    content {
      name = delegation.value.name
      service_delegation {
        name    = delegation.value.service_delegation[0].name
        actions = delegation.value.service_delegation[0].actions
      }
    }
  }

  private_endpoint_network_policies_enabled     = try(each.value.address_prefixes.enable_private_endpoint_policies[0], false)
  private_link_service_network_policies_enabled = try(each.value.address_prefixes.enable_private_link_policies[0], false)
}

# nsg
#----------------------------

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                  = var.nsg_subnet_map
  subnet_id                 = [for k, v in azurerm_subnet.this : v.id if length(regexall("${each.key}", k)) > 0][0]
  network_security_group_id = each.value
  timeouts {
    create = "60m"
  }
}

# dns
#----------------------------

# dns zone

resource "azurerm_private_dns_zone" "this" {
  count               = var.create_private_dns_zone ? 1 : 0
  resource_group_name = var.resource_group
  name                = var.private_dns_zone_name
  tags                = var.tags
}

# zone links

resource "azurerm_private_dns_zone_virtual_network_link" "internal" {
  count                 = var.create_private_dns_zone ? 1 : 0
  resource_group_name   = var.resource_group
  name                  = "${local.prefix}vnet-link"
  private_dns_zone_name = var.create_private_dns_zone ? azurerm_private_dns_zone.this[0].name : var.private_dns_zone_name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = true
  timeouts {
    create = "60m"
  }
}

# zone links to external vnets

resource "azurerm_private_dns_zone_virtual_network_link" "external" {
  for_each              = var.private_dns_zone_linked_external_vnets
  resource_group_name   = var.resource_group
  name                  = "${local.prefix}${each.key}-vnet-link"
  private_dns_zone_name = var.create_private_dns_zone ? azurerm_private_dns_zone.this[0].name : var.private_dns_zone_name
  virtual_network_id    = each.value
  registration_enabled  = false
  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.internal,
  ]
  timeouts {
    create = "60m"
  }
}

# dns resolver

resource "azurerm_private_dns_resolver" "this" {
  count               = var.vnet_config[0].enable_private_dns_resolver ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}dns-resolver"
  location            = var.location
  virtual_network_id  = azurerm_virtual_network.this.id
  timeouts {
    create = "60m"
  }
  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
  ]
  tags = var.tags
}

resource "azurerm_private_dns_resolver_inbound_endpoint" "this" {
  count                   = var.vnet_config[0].enable_private_dns_resolver ? 1 : 0
  name                    = "${local.prefix}dns-in"
  private_dns_resolver_id = azurerm_private_dns_resolver.this[0].id
  location                = var.location
  ip_configurations {
    private_ip_allocation_method = "Dynamic"
    subnet_id                    = azurerm_subnet.this[var.vnet_config[0].private_dns_inbound_subnet_name].id
  }
  timeouts {
    create = "60m"
  }
}

resource "azurerm_private_dns_resolver_outbound_endpoint" "this" {
  count                   = var.vnet_config[0].enable_private_dns_resolver ? 1 : 0
  name                    = "${local.prefix}dns-out"
  private_dns_resolver_id = azurerm_private_dns_resolver.this[0].id
  location                = var.location
  subnet_id               = azurerm_subnet.this[var.vnet_config[0].private_dns_outbound_subnet_name].id
  timeouts {
    create = "60m"
  }
}

# dns resolver links
/*
resource "azurerm_private_dns_resolver_virtual_network_link" "this" {
  for_each                  = { for k, v in var.dns_zone_linked_rulesets : k => v if var.private_dns_zone_name != null }
  name                      = "${local.prefix}${each.key}-vnet-link"
  dns_forwarding_ruleset_id = each.value
  virtual_network_id        = azurerm_virtual_network.this.id
}*/


# nat
#----------------------------

resource "azurerm_public_ip" "nat" {
  count               = length(var.vnet_config[0].nat_gateway_subnet_names) > 0 ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}natgw"
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  timeouts {
    create = "60m"
  }
  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
  ]
  tags = var.tags
}

resource "azurerm_nat_gateway" "nat" {
  count               = length(var.vnet_config[0].nat_gateway_subnet_names) > 0 ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}natgw"
  location            = var.location
  sku_name            = "Standard"
  timeouts {
    create = "60m"
  }
  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
  ]
  tags = var.tags
}

resource "azurerm_nat_gateway_public_ip_association" "nat" {
  count                = length(var.vnet_config[0].nat_gateway_subnet_names) > 0 ? 1 : 0
  nat_gateway_id       = azurerm_nat_gateway.nat[0].id
  public_ip_address_id = azurerm_public_ip.nat[0].id
  timeouts {
    create = "60m"
  }
}

resource "azurerm_subnet_nat_gateway_association" "nat" {
  for_each       = { for s in var.vnet_config[0].nat_gateway_subnet_names : s => local.nat_gateway_subnet_ids[s] }
  subnet_id      = each.value
  nat_gateway_id = azurerm_nat_gateway.nat[0].id
}

# vm
#----------------------------

/* module "vm" {
  for_each                = { for x in var.vm_config : x.name => x }
  source                  = "../../modules/linux"
  resource_group          = var.resource_group
  prefix                  = trimsuffix(local.prefix, "-")
  name                    = each.key
  location                = var.location
  vm_size                 = each.value.size
  subnet                  = azurerm_subnet.this[each.value.subnet].id
  private_ip              = each.value.private_ip
  source_image            = each.value.source_image
  use_vm_extension        = each.value.use_vm_extension
  custom_data             = each.value.custom_data
  enable_public_ip        = each.value.enable_public_ip
  dns_servers             = each.value.dns_servers
  storage_account         = var.storage_account
  admin_username          = var.admin_username
  admin_password          = var.admin_password
  private_dns_zone_name   = var.create_private_dns_zone ? azurerm_private_dns_zone.this[0].name : var.private_dns_zone_name == null ? "" : var.private_dns_zone_name
  private_dns_zone_prefix = var.private_dns_zone_prefix == null ? "" : var.private_dns_zone_prefix
  delay_creation          = each.value.delay_creation
  depends_on = [
    azurerm_public_ip.nat,
    azurerm_nat_gateway.nat,
    azurerm_nat_gateway_public_ip_association.nat,
    #azurerm_subnet_nat_gateway_association.nat,
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
  ]
  tags = var.tags
} */

# vpngw
#----------------------------

resource "azurerm_public_ip" "vpngw_pip0" {
  count               = var.vnet_config[0].enable_vpn_gateway ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}vpngw-pip0"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = [1, 2, 3]
  timeouts {
    create = "60m"
  }
  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
  ]
  tags = var.tags
}

resource "azurerm_public_ip" "vpngw_pip1" {
  count               = var.vnet_config[0].enable_vpn_gateway ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}vpngw-pip1"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  zones               = [1, 2, 3]
  timeouts {
    create = "60m"
  }
  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
  ]
  tags = var.tags
}

resource "azurerm_virtual_network_gateway" "vpngw" {
  count               = var.vnet_config[0].enable_vpn_gateway ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}vpngw"
  location            = var.location
  type                = "Vpn"
  vpn_type            = "RouteBased"
  sku                 = var.vnet_config[0].vpn_gateway_sku
  enable_bgp          = true
  active_active       = true
  tags                = var.tags

  ip_configuration {
    name                          = "${local.prefix}ip-config0"
    subnet_id                     = azurerm_subnet.this["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.vpngw_pip0[0].id
    private_ip_address_allocation = "Dynamic"
  }
  ip_configuration {
    name                          = "${local.prefix}ip-config1"
    subnet_id                     = azurerm_subnet.this["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.vpngw_pip1[0].id
    private_ip_address_allocation = "Dynamic"
  }

  bgp_settings {
    asn = var.vnet_config[0].vpn_gateway_asn
    peering_addresses {
      ip_configuration_name = "${local.prefix}ip-config0"
      apipa_addresses       = try(var.vnet_config.ip_config0_apipa_addresses, ["169.254.21.1"])
    }
    peering_addresses {
      ip_configuration_name = "${local.prefix}ip-config1"
      apipa_addresses       = try(var.vnet_config.ip_config1_apipa_addresses, ["169.254.21.5"])
    }
  }
  timeouts {
    create = "60m"
  }
}

# ergw
#----------------------------

resource "azurerm_public_ip" "ergw_pip" {
  count               = var.vnet_config[0].enable_er_gateway ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}ergw-pip0"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags
  timeouts {
    create = "60m"
  }
  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
  ]
}

resource "azurerm_virtual_network_gateway" "ergw" {
  count               = var.vnet_config[0].enable_er_gateway ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}ergw"
  location            = var.location
  type                = "ExpressRoute"
  vpn_type            = "RouteBased"
  sku                 = "Standard"
  enable_bgp          = true
  active_active       = false
  ip_configuration {
    name                          = "${local.prefix}ip0"
    subnet_id                     = azurerm_subnet.this["GatewaySubnet"].id
    public_ip_address_id          = azurerm_public_ip.ergw_pip[0].id
    private_ip_address_allocation = "Dynamic"
  }
  timeouts {
    create = "60m"
  }
}

# route server
#----------------------------

resource "azurerm_public_ip" "ars_pip" {
  count               = var.vnet_config[0].enable_ars ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}ars-pip"
  location            = var.location
  sku                 = var.vnet_config[0].er_gateway_sku
  allocation_method   = "Static"
  tags                = var.tags
  timeouts {
    create = "60m"
  }
  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
  ]
}

resource "azurerm_route_server" "ars" {
  count                            = var.vnet_config[0].enable_ars ? 1 : 0
  resource_group_name              = var.resource_group
  name                             = "${local.prefix}ars"
  location                         = var.location
  sku                              = "Standard"
  public_ip_address_id             = azurerm_public_ip.ars_pip[0].id
  subnet_id                        = azurerm_subnet.this["RouteServerSubnet"].id
  branch_to_branch_traffic_enabled = true
  tags                             = var.tags

  lifecycle {
    ignore_changes = [
      subnet_id
    ]
  }
  timeouts {
    create = "60m"
  }
  depends_on = [
    azurerm_virtual_network_gateway.vpngw,
    azurerm_virtual_network_gateway.ergw,
  ]
}

# azure firewall
#----------------------------

resource "random_id" "azfw" {
  count       = var.vnet_config[0].create_firewall ? 1 : 0
  byte_length = 4
}

# workspace

resource "azurerm_log_analytics_workspace" "azfw" {
  count               = var.vnet_config[0].create_firewall ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}azfw-ws-${random_id.azfw[0].hex}"
  location            = var.location
  tags                = var.tags
}

# firewall public ip

resource "azurerm_public_ip" "fw_pip" {
  count               = var.vnet_config[0].create_firewall ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}azfw-pip0"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags
  timeouts {
    create = "60m"
  }
  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
  ]
}

# firewall management public ip

resource "azurerm_public_ip" "fw_mgt_pip" {
  count               = var.vnet_config[0].create_firewall ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}azfw-mgt-pip0"
  location            = var.location
  sku                 = "Standard"
  allocation_method   = "Static"
  tags                = var.tags
  timeouts {
    create = "60m"
  }
  depends_on = [
    azurerm_subnet.this,
    azurerm_subnet_network_security_group_association.this,
  ]
}

# firewall

resource "azurerm_firewall" "azfw" {
  count               = var.vnet_config[0].create_firewall ? 1 : 0
  name                = "${local.prefix}azfw"
  resource_group_name = var.resource_group
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = try(var.vnet_config[0].firewall_sku, "Basic")
  firewall_policy_id  = try(var.vnet_config[0].firewall_policy_id, null)
  tags                = var.tags

  ip_configuration {
    name                 = "${local.prefix}ip-config"
    subnet_id            = azurerm_subnet.this["AzureFirewallSubnet"].id
    public_ip_address_id = azurerm_public_ip.fw_pip[0].id
  }
  management_ip_configuration {
    name                 = "${local.prefix}mgmt-ip-config"
    subnet_id            = azurerm_subnet.this["AzureFirewallManagementSubnet"].id
    public_ip_address_id = azurerm_public_ip.fw_mgt_pip[0].id
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
    azurerm_public_ip.fw_mgt_pip,
    azurerm_public_ip.fw_pip,
    azurerm_route_server.ars,
    azurerm_virtual_network_gateway.vpngw,
    azurerm_virtual_network_gateway.ergw,
  ]
}

resource "azurerm_storage_account" "azfw" {
  count                    = var.vnet_config[0].create_firewall ? 1 : 0
  resource_group_name      = var.resource_group
  name                     = lower(replace("${local.prefix}azfw${random_id.azfw[0].hex}", "-", ""))
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

# diagnostic setting

resource "null_resource" "azfw_diag_delete_existing" {
  count = var.vnet_config[0].create_firewall ? 1 : 0
  triggers = {
    delete = "az monitor diagnostic-settings delete --name ${local.prefix}azfw-diag-${random_id.azfw[0].hex} --resource ${azurerm_firewall.azfw[0].id}"
  }
  provisioner "local-exec" {
    command = self.triggers.delete
  }
  provisioner "local-exec" {
    when    = destroy
    command = self.triggers.delete
  }
  depends_on = [
    azurerm_firewall.azfw,
    azurerm_log_analytics_workspace.azfw,
    azurerm_storage_account.azfw,
  ]
}

resource "azurerm_monitor_diagnostic_setting" "azfw" {
  count                      = var.vnet_config[0].create_firewall ? 1 : 0
  name                       = "${local.prefix}azfw-diag-${random_id.azfw[0].hex}"
  target_resource_id         = azurerm_firewall.azfw[0].id
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
    azurerm_firewall.azfw,
    azurerm_log_analytics_workspace.azfw,
    azurerm_storage_account.azfw,
    null_resource.azfw_diag_delete_existing,
  ]
}

