
output "firewall" {
  value = azurerm_firewall.this
}

output "public_ip" {
  value = azurerm_public_ip.pip
}

output "public_ip_mgt" {
  value = azurerm_public_ip.mgt_pip
}

output "private_ip" {
  value = coalesce(
    try(azurerm_firewall.this.ip_configuration[0].private_ip_address, null),
    try(azurerm_firewall.this.virtual_hub[0].private_ip_address, null)
  )
}
