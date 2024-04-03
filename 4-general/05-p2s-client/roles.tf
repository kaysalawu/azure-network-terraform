
# role assignment (system-assigned identity)

locals {
  role_assignments = [
    { role = "Network Contributor", principal_id = module.client1.vm.identity[0].principal_id },
  ]
}

resource "azurerm_role_assignment" "spoke3" {
  count                = length(local.role_assignments)
  scope                = module.hub1.p2s_vpngw.id
  role_definition_name = local.role_assignments[count.index].role
  principal_id         = local.role_assignments[count.index].principal_id
}
