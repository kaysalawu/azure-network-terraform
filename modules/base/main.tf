
locals {
  prefix = var.prefix == "" ? "" : format("%s-", var.prefix)
  nat_gateway_subnet_ids = {
    for k, v in var.vnet_config[0].subnets : k => azurerm_subnet.this[k].id
    if contains(var.vnet_config[0].nat_gateway_subnet_names, k)
  }
}

####################################################
# vnet
####################################################

resource "azurerm_virtual_network" "this" {
  resource_group_name = var.resource_group
  name                = "${local.prefix}vnet"
  address_space       = var.vnet_config[0].address_space
  location            = var.location
  dns_servers         = var.vnet_config[0].dns_servers
  tags                = var.tags
}

####################################################
# subnets
####################################################

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

####################################################
# nsg
####################################################

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each                  = var.nsg_subnet_map
  subnet_id                 = [for k, v in azurerm_subnet.this : v.id if k == each.key][0]
  network_security_group_id = each.value
  timeouts {
    create = "60m"
  }
}

####################################################
# dns
####################################################

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

####################################################
# dns resolver
####################################################

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
    subnet_id                    = azurerm_subnet.this["DnsResolverInboundSubnet"].id
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
  subnet_id               = azurerm_subnet.this["DnsResolverOutboundSubnet"].id
  timeouts {
    create = "60m"
  }
}

# ruleset

resource "azurerm_private_dns_resolver_dns_forwarding_ruleset" "this" {
  count                                      = var.vnet_config[0].enable_private_dns_resolver ? 1 : 0
  resource_group_name                        = var.resource_group
  name                                       = "${local.prefix}ruleset"
  location                                   = var.location
  private_dns_resolver_outbound_endpoint_ids = [azurerm_private_dns_resolver_outbound_endpoint.this[0].id]
}

# dns resolver links (local)

resource "azurerm_private_dns_resolver_virtual_network_link" "this" {
  count                     = var.vnet_config[0].enable_private_dns_resolver ? 1 : 0
  name                      = "${local.prefix}vnet-link"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.this[0].id
  virtual_network_id        = azurerm_virtual_network.this.id
}

# dns resolver links (external)

resource "azurerm_private_dns_resolver_virtual_network_link" "external" {
  for_each                  = { for k, v in var.private_dns_ruleset_linked_external_vnets : k => v if var.vnet_config[0].enable_private_dns_resolver }
  name                      = "${local.prefix}${each.key}-vnet-link"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.this[0].id
  virtual_network_id        = each.value
}

resource "azurerm_private_dns_resolver_forwarding_rule" "this" {
  for_each                  = { for k, v in var.vnet_config[0].ruleset_dns_forwarding_rules : k => v if var.vnet_config[0].enable_private_dns_resolver }
  name                      = "${local.prefix}${each.key}-rule"
  dns_forwarding_ruleset_id = azurerm_private_dns_resolver_dns_forwarding_ruleset.this[0].id
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
# nat
####################################################

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

####################################################
# vm
####################################################

# module "vm" {
#   for_each                = { for x in var.vm_config : x.name => x }
#   source                  = "../../modules/linux"
#   resource_group          = var.resource_group
#   prefix                  = trimsuffix(local.prefix, "-")
#   name                    = each.key
#   location                = var.location
#   vm_size                 = each.value.size
#   subnet                  = azurerm_subnet.this[each.value.subnet].id
#   private_ip              = each.value.private_ip
#   source_image            = each.value.source_image
#   use_vm_extension        = each.value.use_vm_extension
#   custom_data             = each.value.custom_data
#   enable_public_ip        = each.value.enable_public_ip
#   dns_servers             = each.value.dns_servers
#   storage_account         = var.storage_account
#   admin_username          = var.admin_username
#   admin_password          = var.admin_password
#   private_dns_zone_name   = var.create_private_dns_zone ? azurerm_private_dns_zone.this[0].name : var.private_dns_zone_name == null ? "" : var.private_dns_zone_name
#   private_dns_zone_prefix = var.private_dns_zone_prefix == null ? "" : var.private_dns_zone_prefix
#   delay_creation          = each.value.delay_creation
#   depends_on = [
#     azurerm_public_ip.nat,
#     azurerm_nat_gateway.nat,
#     azurerm_nat_gateway_public_ip_association.nat,
#     #azurerm_subnet_nat_gateway_association.nat,
#     azurerm_subnet.this,
#     azurerm_subnet_network_security_group_association.this,
#   ]
#   tags = var.tags
# }

####################################################
# vpngw
####################################################

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

####################################################
# ergw
####################################################

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

####################################################
# route server
####################################################

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

####################################################
# azure firewall
####################################################

resource "random_id" "azfw" {
  count       = var.firewall_config[0].enable ? 1 : 0
  byte_length = 4
}

# workspace

resource "azurerm_log_analytics_workspace" "azfw" {
  count               = var.firewall_config[0].enable ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}azfw-ws-${random_id.azfw[0].hex}"
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

# storage account

resource "azurerm_storage_account" "azfw" {
  count                    = var.firewall_config[0].enable ? 1 : 0
  resource_group_name      = var.resource_group
  name                     = lower(replace("${local.prefix}azfw${random_id.azfw[0].hex}", "-", ""))
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

# firewall public ip

resource "azurerm_public_ip" "fw_pip" {
  count               = var.firewall_config[0].enable ? 1 : 0
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
  count               = var.firewall_config[0].enable ? 1 : 0
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
  count               = var.firewall_config[0].enable ? 1 : 0
  name                = "${local.prefix}azfw"
  resource_group_name = var.resource_group
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = try(var.firewall_config[0].firewall_sku, "Basic")
  firewall_policy_id  = try(var.firewall_config[0].firewall_policy_id, null)
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

# diagnostic setting

resource "azurerm_monitor_diagnostic_setting" "azfw" {
  count                          = var.firewall_config[0].enable ? 1 : 0
  name                           = "${local.prefix}azfw-diag"
  target_resource_id             = azurerm_firewall.azfw[0].id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.azfw[0].id
  log_analytics_destination_type = "Dedicated"
  #storage_account_id         = azurerm_storage_account.azfw[0].id

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
}

####################################################
# nva
####################################################

# linux
#----------------------------

# appliance

module "nva_linux" {
  count                = var.nva_config[0].enable && var.nva_config[0].type == "linux" ? 1 : 0
  source               = "../../modules/linux"
  resource_group       = var.resource_group
  prefix               = local.prefix
  name                 = "nva"
  location             = var.location
  subnet               = azurerm_subnet.this["TrustSubnet"].id
  enable_ip_forwarding = true
  enable_public_ip     = true
  source_image         = "ubuntu-20"
  storage_account      = var.storage_account
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  custom_data          = var.nva_config[0].custom_data
}

# internal lb

resource "azurerm_lb" "nva" {
  count               = var.nva_config[0].enable && var.nva_config[0].type == "linux" ? 1 : 0
  resource_group_name = var.resource_group
  name                = "${local.prefix}nva-lb"
  location            = var.location
  sku                 = "Standard"
  frontend_ip_configuration {
    name                          = "nva-lb-feip"
    subnet_id                     = azurerm_subnet.this["LoadBalancerSubnet"].id
    private_ip_address            = var.nva_config[0].internal_lb_addr
    private_ip_address_allocation = "Static"
  }
  lifecycle {
    ignore_changes = [frontend_ip_configuration, ]
  }
  depends_on = [
    module.nva_linux,
  ]
}

# backend

resource "azurerm_lb_backend_address_pool" "nva" {
  count           = var.nva_config[0].enable && var.nva_config[0].type == "linux" ? 1 : 0
  name            = "${local.prefix}nva-beap"
  loadbalancer_id = azurerm_lb.nva[0].id
}

resource "azurerm_lb_backend_address_pool_address" "nva" {
  count                   = var.nva_config[0].enable && var.nva_config[0].type == "linux" ? 1 : 0
  name                    = "${local.prefix}nva-beap-addr"
  backend_address_pool_id = azurerm_lb_backend_address_pool.nva[0].id
  virtual_network_id      = azurerm_virtual_network.this.id
  ip_address              = module.nva_linux[0].interface.ip_configuration[0].private_ip_address
}

# probe

resource "azurerm_lb_probe" "nva_lb_probe" {
  count               = var.nva_config[0].enable && var.nva_config[0].type == "linux" ? 1 : 0
  name                = "${local.prefix}nva-probe"
  interval_in_seconds = 5
  number_of_probes    = 2
  loadbalancer_id     = azurerm_lb.nva[0].id
  port                = 22
  protocol            = "Tcp"
}

# rule

resource "azurerm_lb_rule" "nva" {
  count    = var.nva_config[0].enable && var.nva_config[0].type == "linux" ? 1 : 0
  name     = "${local.prefix}nva-rule"
  protocol = "All"
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.nva[0].id
  ]
  loadbalancer_id                = azurerm_lb.nva[0].id
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "nva-lb-feip"
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 30
  load_distribution              = "Default"
  probe_id                       = azurerm_lb_probe.nva_lb_probe[0].id
}

# opnsense
#----------------------------

module "opnsense_0" {
  count          = var.nva_config[0].enable && var.nva_config[0].type == "opnsense" ? 1 : 0
  source         = "../../modules/opnsense"
  resource_group = var.resource_group
  prefix         = trimsuffix(local.prefix, "-")
  name           = "opns0"
  location       = var.location

  untrust_subnet_id = azurerm_subnet.this["UntrustSubnet"].id
  trust_subnet_id   = azurerm_subnet.this["TrustSubnet"].id

  scenario_option               = "TwoNics"
  opn_type                      = "TwnoNics"
  deploy_windows_mgmt           = false
  mgmt_subnet_address_prefix    = azurerm_subnet.this["ManagementSubnet"].address_prefixes[0]
  trusted_subnet_address_prefix = azurerm_subnet.this["TrustSubnet"].address_prefixes[0]
}

