
output "vnet" {
  value = azurerm_virtual_network.this
}

output "subnets" {
  value = azurerm_subnet.this
}

/* output "vm" {
  value = { for k, v in module.vm : k => v.vm }
}

output "vm_interface" {
  value = { for k, v in module.vm : k => v.interface }
}

output "vm_public_ip" {
  value = { for k, v in module.vm : k => v.vm.public_ip_address }
} */

output "private_dns_zone" {
  value = try(azurerm_private_dns_zone.this[0], {})
}

output "private_dns_inbound_ep" {
  value = try(azurerm_private_dns_resolver_inbound_endpoint.this[0], {})
}

output "private_dns_outbound_ep" {
  value = try(azurerm_private_dns_resolver_outbound_endpoint.this[0], {})
}

output "ars_public_pip" {
  value = try(azurerm_public_ip.ars_pip[0], {})
}

output "ergw_public_ip" {
  value = try(azurerm_public_ip.ergw_pip[0], {})
}

output "vpngw_public_ip0" {
  value = try(azurerm_public_ip.vpngw_pip0[0].ip_address, {})
}

output "vpngw_public_ip1" {
  value = try(azurerm_public_ip.vpngw_pip1[0].ip_address, {})
}

output "ars" {
  value = try(azurerm_route_server.ars[0], {})
}

output "ars_bgp_asn" {
  value = try(azurerm_route_server.ars[0].virtual_router_asn, {})
}

output "ars_bgp_ip0" {
  value = try(tolist(azurerm_route_server.ars[0].virtual_router_ips)[0], null)
}

output "ars_bgp_ip1" {
  value = try(tolist(azurerm_route_server.ars[0].virtual_router_ips)[1], null)
}

output "ergw" {
  value = try(azurerm_virtual_network_gateway.ergw[0], {})
}

output "vpngw" {
  value = try(azurerm_virtual_network_gateway.vpngw[0], {})
}

output "vpngw_bgp_asn" {
  value = try(azurerm_virtual_network_gateway.vpngw[0].bgp_settings[0].asn, {})
}

output "vpngw_bgp_ip0" {
  value = try(azurerm_virtual_network_gateway.vpngw[0].bgp_settings[0].peering_addresses[0].default_addresses[0], {})
}

output "vpngw_bgp_ip1" {
  value = try(azurerm_virtual_network_gateway.vpngw[0].bgp_settings[0].peering_addresses[1].default_addresses[0], {})
}

output "firewall" {
  value = try(azurerm_firewall.azfw[0], {})
}

output "firewall_public_ip" {
  value = try(azurerm_public_ip.fw_pip[0], null)
}

output "firewall_private_ip" {
  value = try(azurerm_firewall.azfw[0].ip_configuration[0].private_ip_address, {})
}
