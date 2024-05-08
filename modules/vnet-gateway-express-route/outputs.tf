
output "gateway" {
  value = try(azurerm_virtual_network_gateway.this, {})
}

output "gateway_name" {
  value = "${var.prefix}ergw"
}

output "public_ip" {
  value = try(azurerm_public_ip.this, {})
}
