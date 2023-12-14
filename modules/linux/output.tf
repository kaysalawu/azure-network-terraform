
output "vm" {
  value = azurerm_linux_virtual_machine.this
}

output "interface" {
  value = azurerm_network_interface.this
}

output "ip_configuration" {
  value = azurerm_network_interface.this.ip_configuration
}

output "private_ip_address" {
  value = azurerm_network_interface.this.ip_configuration[0].private_ip_address
}

output "public_ip_address" {
  value = try(azurerm_public_ip.this[0].ip_address, null)
}
