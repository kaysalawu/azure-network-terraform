
output "id" {
  description = "the id for the azurerm_lb resource"
  value       = azurerm_lb.this.id
}

output "frontend_ip_configuration" {
  description = "the frontend_ip_configuration for the azurerm_lb resource"
  value       = azurerm_lb.this.frontend_ip_configuration
}

output "probe_ids" {
  description = "the ids for the azurerm_lb_probe resources"
  value       = azurerm_lb_probe.this.*.id
}

output "nat_rule_ids" {
  description = "the ids for the azurerm_lb_nat_rule resources"
  value       = azurerm_lb_nat_rule.this.*.id
}

output "public_ip_id" {
  description = "the id for the azurerm_lb_public_ip resource"
  value       = azurerm_public_ip.this.*.id
}

output "public_ip_address" {
  description = "the ip address for the azurerm_lb_public_ip resource"
  value       = azurerm_public_ip.this.*.ip_address
}

output "backend_address_pool_id" {
  description = "the id for the azurerm_lb_backend_address_pool resource"
  value       = azurerm_lb_backend_address_pool.this.id
}
