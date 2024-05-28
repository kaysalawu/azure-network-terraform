
locals {
  prefix         = var.prefix == "" ? var.name : format("%s-%s-", var.prefix, var.name)
  lb_rules       = { for rule in var.lb_rules : rule.name => rule }
  outbound_rules = { for rule in var.outbound_rules : rule.name => rule }
  nat_rules      = { for rule in var.nat_rules : rule.name => rule }
  probes         = { for probe in var.probes : probe.name => probe }

  backend_pools            = { for pool in var.backend_pools : pool.name => { interfaces = pool.interfaces, addresses = pool.addresses } }  #TODO: convert to list of objects
  backend_pools_addresses  = { for k, v in local.backend_pools : k => v.addresses if length(v.addresses) > 0 && length(v.interfaces) == 0 } #TODO: convert to list of objects
  backend_pools_interfaces = { for k, v in local.backend_pools : k => v.interfaces if length(v.interfaces) > 0 }                            #TODO: convert to list of objects

  backend_pools_addresses_list = flatten([
    for pool_name, address_list in local.backend_pools_addresses : [
      for address in address_list : merge(address, { "pool_name" = pool_name })
    ]
  ])
  backend_pools_interfaces_list = flatten([
    for pool_name, interface_list in local.backend_pools_interfaces : [
      for interface in interface_list : merge(interface, { "pool_name" = pool_name })
    ]
  ])
}

####################################################
# addresses
####################################################

resource "azurerm_public_ip" "this" {
  count               = var.type == "public" ? length(var.frontend_ip_configuration) : 0
  resource_group_name = var.resource_group_name
  name                = "${local.prefix}${var.frontend_ip_configuration[count.index].name}-pip"
  location            = var.location
  allocation_method   = var.allocation_method
  sku                 = var.pip_sku
  zones               = var.frontend_ip_configuration[count.index].zones
  ip_version          = var.enable_dual_stack ? var.frontend_ip_configuration[count.index].public_ip_address_version : "IPv4"
  domain_name_label   = var.frontend_ip_configuration[count.index].domain_name_label
  tags                = var.tags
  lifecycle {
    create_before_destroy = true
  }
}

####################################################
# load balancer
####################################################

resource "azurerm_lb" "this" {
  resource_group_name = var.resource_group_name
  name                = var.type == "public" ? "${local.prefix}elb" : "${local.prefix}ilb"
  location            = var.location
  sku                 = var.lb_sku
  tags                = var.tags

  dynamic "frontend_ip_configuration" {
    for_each = var.frontend_ip_configuration
    content {
      name                          = frontend_ip_configuration.value.name
      public_ip_address_id          = var.type == "public" ? azurerm_public_ip.this[frontend_ip_configuration.key].id : null
      subnet_id                     = var.type == "private" ? lookup(frontend_ip_configuration.value, "subnet_id", null) : null
      zones                         = var.type == "private" ? lookup(frontend_ip_configuration.value, "zones", null) : null
      private_ip_address            = var.type == "private" ? lookup(frontend_ip_configuration.value, "private_ip_address", null) : null
      private_ip_address_allocation = var.type == "private" ? lookup(frontend_ip_configuration.value, "private_ip_address_allocation", null) : null
      private_ip_address_version    = var.type == "private" ? lookup(frontend_ip_configuration.value, "private_ip_address_version", null) : null
    }
  }

  depends_on = [
    azurerm_public_ip.this,
  ]
}

####################################################
# probes
####################################################

resource "azurerm_lb_probe" "this" {
  for_each            = local.probes
  name                = each.value.name
  protocol            = each.value.protocol
  port                = each.value.port
  interval_in_seconds = each.value.interval
  number_of_probes    = each.value.number_of_probes
  request_path        = each.value.request_path
  loadbalancer_id     = azurerm_lb.this.id
}

####################################################
# address pools
####################################################

resource "azurerm_lb_backend_address_pool" "this" {
  for_each        = local.backend_pools
  name            = each.key
  loadbalancer_id = azurerm_lb.this.id
  depends_on      = [azurerm_lb.this]
}

####################################################
# load balacing rules
####################################################

resource "azurerm_lb_rule" "this" {
  for_each                       = local.lb_rules
  name                           = "${each.key}-lb-rule"
  loadbalancer_id                = azurerm_lb.this.id
  probe_id                       = azurerm_lb_probe.this[each.value.probe_name].id
  protocol                       = each.value.protocol
  frontend_port                  = each.value.protocol == "All" ? "0" : each.value.frontend_port
  backend_port                   = each.value.protocol == "All" ? "0" : each.value.backend_port
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
  enable_floating_ip             = each.value.enable_floating_ip
  idle_timeout_in_minutes        = each.value.idle_timeout_in_minutes
  load_distribution              = each.value.load_distribution
  disable_outbound_snat          = each.value.disable_outbound_snat
  backend_address_pool_ids       = [for pool in each.value.backend_address_pool_name : azurerm_lb_backend_address_pool.this[pool].id]
}

resource "azurerm_lb_outbound_rule" "this" {
  for_each                 = local.outbound_rules
  name                     = "${each.key}-snat-rule"
  loadbalancer_id          = azurerm_lb.this.id
  protocol                 = each.value.protocol
  enable_tcp_reset         = each.value.enable_tcp_reset
  idle_timeout_in_minutes  = each.value.idle_timeout_in_minutes
  allocated_outbound_ports = each.value.allocated_outbound_ports
  backend_address_pool_id  = azurerm_lb_backend_address_pool.this[each.value.backend_address_pool_name].id

  frontend_ip_configuration {
    name = each.value.frontend_ip_configuration_name
  }
}

resource "azurerm_lb_nat_rule" "this" {
  for_each                       = local.nat_rules
  resource_group_name            = var.resource_group_name
  name                           = "${each.key}-nat-rule"
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = each.value.protocol
  frontend_port                  = each.value.frontend_port
  backend_port                   = each.value.backend_port
  frontend_ip_configuration_name = each.value.frontend_ip_configuration_name
}

resource "time_sleep" "this" {
  create_duration = "10s"
  depends_on = [
    azurerm_lb_backend_address_pool.this,
  ]
}

# ####################################################
# backend association
# ####################################################

# for a given backend pool, interface association takes precedence over address association
# address association is only used when no interface is specified

resource "azurerm_network_interface_backend_address_pool_association" "this" {
  count                   = length(local.backend_pools_interfaces_list)
  network_interface_id    = local.backend_pools_interfaces_list[count.index].network_interface_id
  ip_configuration_name   = local.backend_pools_interfaces_list[count.index].ip_configuration_name
  backend_address_pool_id = azurerm_lb_backend_address_pool.this[local.backend_pools_interfaces_list[count.index].pool_name].id
  depends_on              = [time_sleep.this, ]
}

resource "azurerm_lb_backend_address_pool_address" "this" {
  count                               = length(local.backend_pools_addresses_list)
  name                                = local.backend_pools_addresses_list[count.index].name
  backend_address_pool_id             = azurerm_lb_backend_address_pool.this[local.backend_pools_addresses_list[count.index].pool_name].id
  backend_address_ip_configuration_id = local.backend_pools_addresses_list[count.index].backend_address_ip_configuration_id
  virtual_network_id                  = local.backend_pools_addresses_list[count.index].virtual_network_id
  ip_address                          = local.backend_pools_addresses_list[count.index].ip_address
  depends_on                          = [time_sleep.this, azurerm_lb.this]
}

####################################################
# dashboard
####################################################

locals {
  dashboard_properties = templatefile("${path.module}/templates/dashboard.json", local.dashboard_vars)
  dashboard_vars = {
    LOAD_BALANCER_ID = azurerm_lb.this.id
  }
}

resource "azurerm_portal_dashboard" "this" {
  count                = var.log_analytics_workspace_name != null ? 1 : 0
  name                 = "${local.prefix}azlb-db"
  resource_group_name  = var.resource_group_name
  location             = var.location
  tags                 = var.tags
  dashboard_properties = local.dashboard_properties
}

