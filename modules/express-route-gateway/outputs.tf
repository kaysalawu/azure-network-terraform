
output "gateway" {
  value = azurerm_express_route_gateway.this
}

output "gateway_name" {
  value = "${var.prefix}ergw"
}
