
output "vm" {
  value = azurerm_linux_virtual_machine.this
}

output "interface" {
  value = azurerm_network_interface.this
}

output "public_ip" {
  value = try(azurerm_public_ip.this[0].ip_address, null)
}
