
locals {
  prefix = var.prefix == "" ? "" : format("%s-", var.prefix)
}

# route table

resource "azurerm_route_table" "this" {
  resource_group_name = var.resource_group
  name                = "${local.prefix}rt"
  location            = var.location

  disable_bgp_route_propagation = var.disable_bgp_route_propagation
}

# delay

resource "time_sleep" "this" {
  depends_on = [
    azurerm_route_table.this
  ]
  create_duration = var.delay_creation
}

# subnet association

resource "azurerm_subnet_route_table_association" "this" {
  subnet_id      = var.subnet_id
  route_table_id = azurerm_route_table.this.id
}

# routes

resource "azurerm_route" "this" {
  for_each               = var.destinations
  resource_group_name    = var.resource_group
  name                   = "${local.prefix}${each.key}-${replace(replace(each.value, ".", "-"), "/", "_")}"
  route_table_name       = azurerm_route_table.this.name
  address_prefix         = each.value
  next_hop_type          = var.next_hop_type
  next_hop_in_ip_address = var.next_hop_in_ip_address
  depends_on             = [time_sleep.this]
}
