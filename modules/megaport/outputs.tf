
# expressroute circuits

output "express_route_circuit" {
  value = azurerm_express_route_circuit.this
}

output "express_route_circuit_peering" {
  value = azurerm_express_route_circuit_peering.this
}

output "mcr" {
  value = megaport_mcr.this
}
