
# role assignments (system-assigned identity)

locals {
  role_assignments = [
    { role = "Reader", scope = azurerm_resource_group.rg.id, principal_id = module.ecs_appsrv1_vm.vm.identity[0].principal_id },
    { role = "Reader", scope = azurerm_resource_group.rg.id, principal_id = module.ecs_test_vm.vm.identity[0].principal_id },
    { role = "Reader", scope = azurerm_resource_group.rg.id, principal_id = module.ecs_cgs.vm.identity[0].principal_id },
  ]
}

resource "azurerm_role_assignment" "roles" {
  count                = length(local.role_assignments)
  scope                = local.role_assignments[count.index].scope
  role_definition_name = local.role_assignments[count.index].role
  principal_id         = local.role_assignments[count.index].principal_id
}
