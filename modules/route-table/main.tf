
locals {
  prefix = var.prefix == "" ? "" : format("%s-", var.prefix)
  routes_ = { for v in var.routes : v.name => [
    for prefix in v.address_prefix : {
      name                   = v.name
      route_name             = "${v.name}--${replace(replace(replace(prefix, ".", "-"), "/", "_"), ":", "-")}"
      address_prefix         = prefix
      next_hop_type          = v.next_hop_type
      next_hop_in_ip_address = v.next_hop_in_ip_address
      delay_creation         = v.delay_creation
    }]
  }
  routes = flatten([for k, v in local.routes_ : v])
}

# route table

resource "azurerm_route_table" "this" {
  resource_group_name = var.resource_group
  name                = "${local.prefix}rt"
  location            = var.location

  disable_bgp_route_propagation = var.disable_bgp_route_propagation
}

# subnet association

resource "azurerm_subnet_route_table_association" "this" {
  subnet_id      = var.subnet_id
  route_table_id = azurerm_route_table.this.id
}

# routes

resource "azurerm_route" "this" {
  for_each               = { for v in local.routes : v.route_name => v }
  resource_group_name    = var.resource_group
  name                   = each.value.route_name
  route_table_name       = azurerm_route_table.this.name
  address_prefix         = each.value.address_prefix
  next_hop_type          = each.value.next_hop_type
  next_hop_in_ip_address = each.value.next_hop_in_ip_address
}
