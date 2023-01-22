
output "vnet" {
  value = azurerm_virtual_network.this
}

output "subnets" {
  value = azurerm_subnet.this
}

output "vm" {
  value = { for k, v in module.vm : k => v.vm }
}

output "interface" {
  value = { for k, v in module.vm : k => v.interface }
}

output "private_dns_zone" {
  value = azurerm_private_dns_zone.this
}

output "private_dns_inbound_ep" {
  value = try(azurerm_private_dns_resolver_inbound_endpoint.this[0], {})
}

output "private_dns_outbound_ep" {
  value = try(azurerm_private_dns_resolver_outbound_endpoint.this[0], {})
}

output "ars_pip" {
  value = try(azurerm_public_ip.ars_pip[0], {})
}

output "ergw_pip" {
  value = try(azurerm_public_ip.ergw_pip[0], {})
}

output "vpngw_pip0" {
  value = try(azurerm_public_ip.vpngw_pip0[0], {})
}

output "vpngw_pip1" {
  value = try(azurerm_public_ip.vpngw_pip1[0], {})
}

output "ars" {
  value = try(azurerm_route_server.ars[0], {})
}

output "ergw" {
  value = try(azurerm_virtual_network_gateway.ergw[0], {})
}

output "vpngw" {
  value = try(azurerm_virtual_network_gateway.vpngw[0], {})
}
