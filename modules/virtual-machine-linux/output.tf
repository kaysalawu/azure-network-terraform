
output "vm" {
  value = azurerm_linux_virtual_machine.this
}

output "interfaces" {
  value = try(azurerm_network_interface.this, {})
}

output "interface_names" {
  value = { for i in try(azurerm_network_interface.this, {}) : i.name => i.name }
}

output "interface_ids" {
  value = { for i in try(azurerm_network_interface.this, {}) : i.name => i.id }
}

output "private_ip_addresses" {
  value = { for i in try(azurerm_network_interface.this, {}) : i.name => i.private_ip_address }
}

# output "public_ip_addresses" {
#   value = { for i in try(azurerm_network_interface.this, {}) : i.name => i.ip_configuration[0].public_ip_address }
# }
