
output "vm" {
  value = azurerm_linux_virtual_machine.this
}

output "interface_untrust" {
  value = azurerm_network_interface.untrust
}

output "interface_trust" {
  value = azurerm_network_interface.trust
}
