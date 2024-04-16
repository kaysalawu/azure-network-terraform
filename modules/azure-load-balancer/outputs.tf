
output "id" {
  description = "the id for the azurerm_lb resource"
  value       = azurerm_lb.this.id
}

output "frontend_ip_configurations" {
  description = "the frontend_ip_configuration for the azurerm_lb resource"
  value       = try({ for feip in azurerm_lb.this.frontend_ip_configuration : feip.name => feip }, {})
}

output "frontend_ip_configuration_ids" {
  description = "the frontend_ip_configuration_ids for the azurerm_lb resource"
  value       = try({ for feip in azurerm_lb.this.frontend_ip_configuration : feip.name => feip.id }, {})
}

output "probe_ids" {
  description = "the ids for the azurerm_lb_probe resources"
  value       = try({ for probe in azurerm_lb_probe.this : probe.name => probe.id }, {})
}

output "nat_rule_ids" {
  description = "the ids for the azurerm_lb_nat_rule resources"
  value       = try({ for nat_rule in azurerm_lb_nat_rule.this : nat_rule.name => nat_rule.id }, {})
}

output "public_ip_address_ids" {
  description = "The IDs for the azurerm_public_ip resource indexed by frontend IP configuration names."
  value = {
    for idx, pip in azurerm_public_ip.this :
    var.frontend_ip_configuration[idx].name => pip.id
  }
}

output "public_ip_addresses" {
  description = "The IP addresses for the azurerm_public_ip resource indexed by frontend IP configuration names."
  value = {
    for idx, pip in azurerm_public_ip.this :
    var.frontend_ip_configuration[idx].name => pip.ip_address
  }
}

output "backend_address_pool_ids" {
  description = "the id for the azurerm_lb_backend_address_pool resource"
  value       = try({ for pool in azurerm_lb_backend_address_pool.this : pool.name => pool.id }, {})
}

