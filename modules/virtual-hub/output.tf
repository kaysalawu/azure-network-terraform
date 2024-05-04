
# virtual hub
#----------------------------------------------------

output "router_bgp_ip0" {
  value = azurerm_virtual_hub.this.virtual_router_ips[1]
}

output "router_bgp_ip1" {
  value = azurerm_virtual_hub.this.virtual_router_ips[0]
}

output "firewall" {
  value = try(module.azfw[0], {})
}

output "firewall_private_ip" {
  value = try(module.azfw[0].private_ip, "")
}

output "virtual_hub" {
  value = azurerm_virtual_hub.this
}

output "bgp_asn" {
  value = azurerm_virtual_hub.this.virtual_router_asn
}

# point-to-site gateway
#----------------------------------------------------

output "p2sgw" {
  value = try(module.p2sgw[0].gateway, {})
}

# vpn gateway
#----------------------------------------------------

output "vpngw" {
  value = try(module.vpngw[0].gateway, {})
}

output "vpngw_public_ip0" {
  value = try(module.vpngw[0].public_ip0, {})
}

output "vpngw_public_ip1" {
  value = try(module.vpngw[0].public_ip1, {})
}

output "vpngw_bgp_ip0" {
  value = try(module.vpngw[0].bgp_default_ip0, {})
}

output "vpngw_bgp_ip1" {
  value = try(module.vpngw[0].bgp_default_ip1, {})
}

# express route gateway
#----------------------------------------------------

output "ergw" {
  value = try(module.ergw[0].gateway, {})
}

