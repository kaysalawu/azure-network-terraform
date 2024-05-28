
locals {
  object_ids = [
    module.hub_server1_vm.vm.identity[0].principal_id,
    module.hub_server2_vm.vm.identity[0].principal_id,
    module.hub_proxy.vm.identity[0].principal_id,
  ]
  role_definitions = [
    "Network Contributor",
  ]

  role_assignments = flatten([
    for oid in local.object_ids : [
      for role in local.role_definitions : {
        id   = "${oid}-${role}"
        oid  = oid
        role = role
      }
    ]
  ])

  assignment_map = { for ra in local.role_assignments : ra.id => {
    "principal_id" : ra.oid,
    "role_definition" : ra.role
  } }
}

resource "azurerm_role_assignment" "combined_role_assignment" {
  count                = length(local.role_assignments)
  scope                = azurerm_resource_group.rg.id
  role_definition_name = local.role_assignments[count.index].role
  principal_id         = local.role_assignments[count.index].oid
}

####################################################
# storage
####################################################

# account

resource "azurerm_storage_account" "storage" {
  resource_group_name      = azurerm_resource_group.rg.name
  name                     = local.storage_storage_account_name
  location                 = local.hub_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.hub_tags
}

# container

resource "azurerm_storage_container" "storage" {
  name                  = local.storage_container_name
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# blob

resource "azurerm_storage_blob" "storage" {
  name                   = "storage.txt"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.storage.name
  type                   = "Block"
  source_content         = local.storage_blob_content
}

# roles

resource "azurerm_role_assignment" "storage" {
  count                = length(local.object_ids)
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = local.object_ids[count.index]
}

resource "azurerm_role_assignment" "blob" {
  count                = length(local.object_ids)
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.object_ids[count.index]
}

####################################################
# key vault
####################################################

# vault

resource "azurerm_key_vault" "key_vault" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.hub_location
  name                = "${local.hub_prefix}kv${random_id.random.hex}"
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = local.hub_tags
}

# policies

resource "azurerm_key_vault_access_policy" "current" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore",
    "Create", "Decrypt", "Encrypt", "Import", "Update",
  ]
  secret_permissions = [
    "Backup", "Delete", "Get", "List", "Purge", "Recover", "Restore", "Set"
  ]
}

resource "azurerm_key_vault_access_policy" "key_vault" {
  count        = length(local.object_ids)
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = local.object_ids[count.index]

  key_permissions    = ["Get", "List", ]
  secret_permissions = ["Get", "List", "Set", ]
}

resource "time_sleep" "key_vault" {
  create_duration = "30s"
  depends_on = [
    azurerm_key_vault_access_policy.current,
    azurerm_key_vault_access_policy.key_vault,
  ]
}

# secret

resource "azurerm_key_vault_secret" "key_vault" {
  name         = local.key_vault_secret_name
  value        = local.key_vault_secret_value
  key_vault_id = azurerm_key_vault.key_vault.id
  depends_on = [
    time_sleep.key_vault,
  ]
}
