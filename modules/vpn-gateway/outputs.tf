
locals {
  tunnel_ips_0       = tolist(azurerm_vpn_gateway.this.bgp_settings[0].instance_0_bgp_peering_address[0].tunnel_ips)
  tunnel_ips_1       = tolist(azurerm_vpn_gateway.this.bgp_settings[0].instance_1_bgp_peering_address[0].tunnel_ips)
  tunnel_ips_0_split = { for addr in local.tunnel_ips_0 : addr => split(".", addr) }
  tunnel_ips_1_split = { for addr in local.tunnel_ips_1 : addr => split(".", addr) }
  public_ip0         = [for addr, parts in local.tunnel_ips_0_split : addr if !(parts[0] == "10" || (parts[0] == "172" && parts[1] >= "16" && parts[1] <= "31") || (parts[0] == "192" && parts[1] == "168"))][0]
  public_ip1         = [for addr, parts in local.tunnel_ips_1_split : addr if !(parts[0] == "10" || (parts[0] == "172" && parts[1] >= "16" && parts[1] <= "31") || (parts[0] == "192" && parts[1] == "168"))][0]
  private_ip0        = [for addr, parts in local.tunnel_ips_0_split : addr if(parts[0] == "10" || (parts[0] == "172" && parts[1] >= "16" && parts[1] <= "31") || (parts[0] == "192" && parts[1] == "168"))][0]
  private_ip1        = [for addr, parts in local.tunnel_ips_1_split : addr if(parts[0] == "10" || (parts[0] == "172" && parts[1] >= "16" && parts[1] <= "31") || (parts[0] == "192" && parts[1] == "168"))][0]
}

output "gateway" {
  value = azurerm_vpn_gateway.this
}

output "public_ip0" {
  value = local.public_ip0
}

output "public_ip1" {
  value = local.public_ip1
}

output "bgp_default_ip0" {
  value = tolist(azurerm_vpn_gateway.this.bgp_settings[0].instance_0_bgp_peering_address[0].default_ips)[0]
}

output "bgp_default_ip1" {
  value = tolist(azurerm_vpn_gateway.this.bgp_settings[0].instance_1_bgp_peering_address[0].default_ips)[0]
}
