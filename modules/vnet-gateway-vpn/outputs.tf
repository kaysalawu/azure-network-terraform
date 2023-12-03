
output "gateway" {
  value = azurerm_virtual_network_gateway.this
}

output "bgp_asn" {
  value = azurerm_virtual_network_gateway.this.bgp_settings[0].asn
}

output "public_ip0" {
  value = azurerm_public_ip.pip0.ip_address
}

output "public_ip1" {
  value = azurerm_public_ip.pip1.ip_address
}

output "bgp_ip0" {
  value = azurerm_virtual_network_gateway.this.bgp_settings[0].peering_addresses[0].default_addresses[0]
}

output "bgp_ip1" {
  value = azurerm_virtual_network_gateway.this.bgp_settings[0].peering_addresses[1].default_addresses[0]
}
