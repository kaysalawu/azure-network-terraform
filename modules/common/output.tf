
output "storage_accounts" {
  value = azurerm_storage_account.storage_accounts
}

output "log_analytics_workspaces" {
  value = azurerm_log_analytics_workspace.log_analytics_workspaces
}

output "nsg_default" {
  value = azurerm_network_security_group.nsg_default
}

output "nsg_main" {
  value = azurerm_network_security_group.nsg_main
}

output "nsg_aks" {
  value = azurerm_network_security_group.nsg_aks
}

output "nsg_nva" {
  value = azurerm_network_security_group.nsg_nva
}

output "nsg_lb" {
  value = azurerm_network_security_group.nsg_lb
}

output "private_dns_zones" {
  value = azurerm_private_dns_zone.private_dns_zones
}
