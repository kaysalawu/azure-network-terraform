
output "gateway" {
  value = azurerm_virtual_network_gateway.this
}

output "bgp_asn" {
  value = azurerm_virtual_network_gateway.this.bgp_settings[0].asn
}

output "public_ip0" {
  value = azurerm_virtual_network_gateway.this.bgp_settings[0].peering_addresses[0].tunnel_ip_addresses[0]
}

output "public_ip1" {
  value = azurerm_virtual_network_gateway.this.bgp_settings[0].peering_addresses[1].tunnel_ip_addresses[0]
}

output "private_ip0" {
  value = azurerm_virtual_network_gateway.this.bgp_settings[0].peering_addresses[0].tunnel_ip_addresses[1]
}

output "private_ip1" {
  value = azurerm_virtual_network_gateway.this.bgp_settings[0].peering_addresses[1].tunnel_ip_addresses[1]
}

output "bgp_default_ip0" {
  value = azurerm_virtual_network_gateway.this.bgp_settings[0].peering_addresses[0].default_addresses[0]
}


output "bgp_default_ip1" {
  value = azurerm_virtual_network_gateway.this.bgp_settings[0].peering_addresses[1].default_addresses[0]
}
