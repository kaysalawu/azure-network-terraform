
# dns
#-----------------------------

output "private_dns_forwarding_ruleset" {
  value = azurerm_private_dns_resolver_dns_forwarding_ruleset.this
}

output "private_dns_resolver" {
  value = azurerm_private_dns_resolver.this
}

output "private_dns_inbound_ep" {
  value = azurerm_private_dns_resolver_inbound_endpoint.this
}

output "private_dns_outbound_ep" {
  value = azurerm_private_dns_resolver_outbound_endpoint.this
}
