
locals {
  public_ip_addresses = [for i in var.ip_configuration :
    i.public_ip_address_name != null ? data.azurerm_public_ip.this[i.name].ip_address :
    azurerm_public_ip.this[i.name].ip_address
  ]
  bgp_default_ips = [for i in azurerm_virtual_network_gateway.this.bgp_settings[0].peering_addresses : i.default_addresses[0]]
}

output "gateway" {
  value = azurerm_virtual_network_gateway.this
}

output "bgp_asn" {
  value = azurerm_virtual_network_gateway.this.bgp_settings[0].asn
}

output "public_ip0" {
  value = length(local.public_ip_addresses) > 0 ? local.public_ip_addresses[0] : null
}

output "public_ip1" {
  value = length(local.public_ip_addresses) > 1 ? local.public_ip_addresses[1] : null
}

output "bgp_default_ip0" {
  value = length(local.bgp_default_ips) > 0 ? local.bgp_default_ips[0] : null
}


output "bgp_default_ip1" {
  value = length(local.bgp_default_ips) > 1 ? local.bgp_default_ips[1] : null
}
