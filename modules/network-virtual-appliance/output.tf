
output "nva_0" {
  value = module.nva_0
}

output "public_ip_untrust_0" {
  value = try(azurerm_public_ip.untrust_0[0].ip_address, null)
}

output "public_ip_untrust_1" {
  value = try(azurerm_public_ip.untrust_1[0].ip_address, null)
}
