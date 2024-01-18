
output "vm" {
  value = azurerm_linux_virtual_machine.this
}

output "interfaces" {
  value = azurerm_network_interface.this
}
