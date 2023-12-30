
# network
#-----------------------------

output "vnet" {
  value = azurerm_virtual_network.this
}

output "subnets" {
  value = azurerm_subnet.this
}

# dns
#-----------------------------

output "private_dns_forwarding_ruleset" {
  value = try(module.dns_resolver[0].private_dns_forwarding_ruleset, {})
}

output "private_dns_zone" {
  value = try(azurerm_private_dns_zone.this[0], {})
}

output "private_dns_resolver" {
  value = try(module.dns_resolver[0].private_dns_resolver, {})
}

output "private_dns_inbound_ep" {
  value = try(module.dns_resolver[0].private_dns_inbound_ep, {})
}

output "private_dns_outbound_ep" {
  value = try(module.dns_resolver[0].private_dns_outbound_ep, {})
}

# ars
#-----------------------------

output "ars_public_pip" {
  value = try(azurerm_public_ip.ars_pip[0], {})
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

# ergw
#-----------------------------

output "ergw" {
  value = try(module.ergw[0].gateway, {})
}

output "ergw_public_ip" {
  value = try(module.ergw[0].public_ip, {})
}

# vpngw
#-----------------------------

output "vpngw" {
  value = try(module.vpngw[0].gateway, {})
}

output "vpngw_bgp_asn" {
  value = try(module.vpngw[0].bgp_asn, {})
}

output "vpngw_public_ip0" {
  value = try(module.vpngw[0].public_ip0, {})
}

output "vpngw_public_ip1" {
  value = try(module.vpngw[0].public_ip1, {})
}

output "vpngw_bgp_ip0" {
  value = try(module.vpngw[0].bgp_ip0, {})
}

output "vpngw_bgp_ip1" {
  value = try(module.vpngw[0].bgp_ip1, {})
}

# firewall
#-----------------------------

output "firewall" {
  value = try(module.azfw[0].firewall, {})
}

output "firewall_public_ip" {
  value = try(module.azfw[0].public_ip, null)
}

output "firewall_private_ip" {
  value = try(module.azfw[0].private_ip, null)
}
