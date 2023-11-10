
output "vpngw" {
  value = azurerm_vpn_gateway.this[0]
}

output "vpngw_public_ip0" {
  value = try(tolist(azurerm_vpn_gateway.this[0].bgp_settings[0].instance_0_bgp_peering_address[0].tunnel_ips)[1], {})
}

output "vpngw_public_ip1" {
  value = try(tolist(azurerm_vpn_gateway.this[0].bgp_settings[0].instance_1_bgp_peering_address[0].tunnel_ips)[1], {})
}

output "vpngw_bgp_ip0" {
  value = try(tolist(azurerm_vpn_gateway.this[0].bgp_settings[0].instance_0_bgp_peering_address[0].default_ips)[0], {})
}

output "vpngw_bgp_ip1" {
  value = try(tolist(azurerm_vpn_gateway.this[0].bgp_settings[0].instance_1_bgp_peering_address[0].default_ips)[0], {})
}

output "router_bgp_ip0" {
  value = try(azurerm_virtual_hub.this.virtual_router_ips[1], {})
}

output "router_bgp_ip1" {
  value = try(azurerm_virtual_hub.this.virtual_router_ips[0], {})
}

output "firewall" {
  value = try(azurerm_firewall.this[0], {})
}

output "firewall_private_ip" {
  value = try(azurerm_firewall.this[0].virtual_hub[0].private_ip_address, {})
}

output "virtual_hub" {
  value = azurerm_virtual_hub.this
}

output "bgp_asn" {
  value = azurerm_virtual_hub.this.virtual_router_asn
}
