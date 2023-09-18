
# Azure load balancer module

locals {
  prefix = var.prefix == "" ? "" : format("%s-", var.prefix)

  frontend_ip_configuration_name_private = "${local.prefix}feip-private"
  frontend_ip_configuration_name_public  = "${local.prefix}feip-public"
}

resource "azurerm_public_ip" "this" {
  count               = var.type == "public" ? 1 : 0
  resource_group_name = var.resource_group_name
  name                = "${local.prefix}pip"
  location            = var.location
  allocation_method   = var.allocation_method
  sku                 = var.pip_sku
  tags                = var.tags
}

resource "azurerm_lb" "this" {
  resource_group_name = var.resource_group_name
  name                = "${local.prefix}lb"
  location            = var.location
  sku                 = var.lb_sku
  tags                = var.tags

  frontend_ip_configuration {
    name                          = var.type == "public" ? local.frontend_ip_configuration_name_public : local.frontend_ip_configuration_name_private
    public_ip_address_id          = var.type == "public" ? join("", azurerm_public_ip.this.*.id) : null
    subnet_id                     = var.type == "public" ? null : var.frontend_subnet_id
    private_ip_address            = var.type == "public" ? null : var.frontend_private_ip_address
    private_ip_address_allocation = var.type == "public" ? null : var.frontend_private_ip_address_allocation
  }
}

resource "azurerm_lb_backend_address_pool" "this" {
  name            = "${local.prefix}beap"
  loadbalancer_id = azurerm_lb.this.id
}

resource "azurerm_lb_probe" "this" {
  count               = length(var.lb_probe)
  name                = element(keys(var.lb_probe), count.index)
  loadbalancer_id     = azurerm_lb.this.id
  protocol            = element(var.lb_probe[element(keys(var.lb_probe), count.index)], 0)
  port                = element(var.lb_probe[element(keys(var.lb_probe), count.index)], 1)
  interval_in_seconds = var.lb_probe_interval
  number_of_probes    = var.lb_probe_unhealthy_threshold
  request_path        = element(var.lb_probe[element(keys(var.lb_probe), count.index)], 2)
}

resource "azurerm_lb_rule" "this" {
  count                          = length(var.lb_port)
  name                           = "${local.prefix}nat-rule-${element(keys(var.lb_port), count.index)}"
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = element(var.lb_port[element(keys(var.lb_port), count.index)], 1)
  frontend_port                  = element(var.lb_port[element(keys(var.lb_port), count.index)], 0)
  backend_port                   = element(var.lb_port[element(keys(var.lb_port), count.index)], 2)
  frontend_ip_configuration_name = var.type == "public" ? local.frontend_ip_configuration_name_public : local.frontend_ip_configuration_name_private
  enable_floating_ip             = false
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]
  idle_timeout_in_minutes        = 5
  probe_id                       = element(azurerm_lb_probe.this.*.id, count.index)
}

resource "azurerm_lb_nat_rule" "this" {
  count                          = length(var.remote_port)
  name                           = "${local.prefix}lb-nat-rule-${count.index}"
  resource_group_name            = var.resource_group_name
  loadbalancer_id                = azurerm_lb.this.id
  protocol                       = "Tcp"
  frontend_port                  = "5000${count.index + 1}"
  backend_port                   = element(var.remote_port[element(keys(var.remote_port), count.index)], 1)
  frontend_ip_configuration_name = var.type == "public" ? local.frontend_ip_configuration_name_public : local.frontend_ip_configuration_name_private
}

resource "azurerm_private_dns_a_record" "this" {
  count               = var.type == "public" ? 0 : 1
  resource_group_name = var.resource_group_name
  name                = var.dns_host
  zone_name           = var.private_dns_zone
  ttl                 = 300
  records             = [azurerm_lb.this.frontend_ip_configuration[0].private_ip_address, ]
}

resource "azurerm_network_interface_backend_address_pool_association" "this" {
  count                   = length(var.backends)
  network_interface_id    = var.backends[count.index].network_interface_id
  ip_configuration_name   = var.backends[count.index].ip_configuration_name
  backend_address_pool_id = azurerm_lb_backend_address_pool.this.id
  depends_on              = [azurerm_lb_backend_address_pool.this]
}


