
locals {
  prefix = var.prefix == "" ? "" : format("%s-", var.prefix)
}

# privatelink service

resource "azurerm_private_link_service" "this" {
  resource_group_name = var.resource_group
  name                = "${local.prefix}pls"
  location            = var.location

  nat_ip_configuration {
    name               = "${local.prefix}${var.nat_ip_config[0].name}"
    primary            = var.nat_ip_config[0].primary
    subnet_id          = var.nat_ip_config[0].subnet_id
    private_ip_address = var.nat_ip_config[0].private_ip_address == "" ? null : var.nat_ip_config[0].private_ip_address
  }

  load_balancer_frontend_ip_configuration_ids = var.nat_ip_config[0].lb_frontend_ids

  lifecycle {
    ignore_changes = [
      nat_ip_configuration
    ]
  }
  timeouts {
    create = "60m"
  }
}

# private dns

/*resource "azurerm_private_dns_a_record" "this" {
  count               = var.type == "public" ? 0 : 1
  resource_group_name = var.resource_group_name
  name                = var.dns_host
  zone_name           = var.private_dns_zone
  ttl                 = 300
  records             = [azurerm_lb.this.frontend_ip_configuration[0].private_ip_address, ]
}*/
