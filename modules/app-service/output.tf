
output "url" {
  value = azurerm_linux_web_app.this.default_hostname
}

output "app_service_id" {
  value = azurerm_linux_web_app.this.id
}
