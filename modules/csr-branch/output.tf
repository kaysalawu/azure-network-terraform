
output "vm" {
  value = azurerm_linux_virtual_machine.this
}

output "interface_ext" {
  value = azurerm_network_interface.ext
}

output "interface_int" {
  value = azurerm_network_interface.int
}
