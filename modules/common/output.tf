
output "storage_accounts" {
  value = azurerm_storage_account.storage_accounts
}

# output "analytics_workspaces" {
#   value = azurerm_log_analytics_workspace.analytics_workspaces
# }

output "nsg_default" {
  value = azurerm_network_security_group.nsg_default
}

output "nsg_main" {
  value = azurerm_network_security_group.nsg_main
}

output "nsg_nva" {
  value = azurerm_network_security_group.nsg_nva
}

output "nsg_appgw" {
  value = azurerm_network_security_group.nsg_appgw
}
