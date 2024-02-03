
output "gateway" {
  value = azurerm_vpn_gateway.this
}

output "public_ip0" {
  value = tolist(azurerm_vpn_gateway.this.bgp_settings[0].instance_0_bgp_peering_address[0].tunnel_ips)[1]
}

output "public_ip1" {
  value = tolist(azurerm_vpn_gateway.this.bgp_settings[0].instance_1_bgp_peering_address[0].tunnel_ips)[1]
}

output "bgp_default_ip0" {
  value = tolist(azurerm_vpn_gateway.this.bgp_settings[0].instance_0_bgp_peering_address[0].default_ips)[0]
}

output "bgp_default_ip1" {
  value = tolist(azurerm_vpn_gateway.this.bgp_settings[0].instance_1_bgp_peering_address[0].default_ips)[0]
}
