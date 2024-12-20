
# network
#-----------------------------

output "vnet" {
  value = azurerm_virtual_network.this
}

output "subnets" {
  value = merge(
    try(azurerm_subnet.this, {}),
    try(azapi_resource.subnets, {})
  )
}

# dns
#-----------------------------

output "private_dns_forwarding_ruleset" {
  value = try(module.dns_resolver[0].private_dns_forwarding_ruleset, {})
}

output "private_dns_zones" {
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

output "ergw_name" {
  value = try(module.ergw[0].gateway_name, "")
}

output "ergw_public_ip" {
  value = try(module.ergw[0].public_ip, {})
}

# s2s vpngw
#-----------------------------

output "s2s_vpngw" {
  value = try(module.s2s_vpngw[0].gateway, {})
}

output "s2s_vpngw_bgp_asn" {
  value = try(module.s2s_vpngw[0].bgp_asn, {})
}

output "s2s_vpngw_public_ip0" {
  value = try(module.s2s_vpngw[0].public_ip0, {})
}

output "s2s_vpngw_public_ip1" {
  value = try(module.s2s_vpngw[0].public_ip1, {})
}

output "s2s_vpngw_private_ip0" {
  value = try(module.s2s_vpngw[0].private_ip0, {})
}

output "s2s_vpngw_private_ip1" {
  value = try(module.s2s_vpngw[0].private_ip1, {})
}

output "s2s_vpngw_bgp_default_ip0" {
  value = try(module.s2s_vpngw[0].bgp_default_ip0, {})
}

output "s2s_vpngw_bgp_default_ip1" {
  value = try(module.s2s_vpngw[0].bgp_default_ip1, {})
}

# p2s vpngw
#-----------------------------

output "p2s_vpngw" {
  value = try(module.p2s_vpngw[0].gateway, {})
}

output "p2s_vpngw_public_ip" {
  value = try(module.p2s_vpngw[0].public_ip, {})
}

output "p2s_client_certificates" {
  value = try(module.p2s_vpngw[0].client_certificates, {})
}

output "p2s_client_certificates_cert_name" {
  value = try(module.p2s_vpngw[0].client_certificates_cert_name, {})
}

output "p2s_client_certificates_private_key_pem" {
  value = try(module.p2s_vpngw[0].client_certificates_private_key_pem, {})
}

output "p2s_client_certificates_cert_pem" {
  value = try(module.p2s_vpngw[0].client_certificates_cert_pem, {})
}

output "p2s_client_certificates_cert_pfx" {
  value = try(module.p2s_vpngw[0].client_certificates_cert_pfx, {})
}

output "p2s_client_certificates_cert_pfx_password" {
  value = try(module.p2s_vpngw[0].client_certificates_cert_pfx_password, {})
}

output "p2s_client_certificates_print" {
  value = try(module.p2s_vpngw[0].client_certificates_print, {})
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

# nva
#-----------------------------

output "nva_public_ip0" {
  value = try(module.nva[0].public_ip_untrust_0, {})
}
