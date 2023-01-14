
output "vm" {
  value = azurerm_linux_virtual_machine.this
}

output "interface" {
  value = azurerm_network_interface.this
}
