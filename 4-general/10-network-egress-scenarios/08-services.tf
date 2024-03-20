
locals {
  storage_storage_account_name = lower(replace("${local.ecs_prefix}sa${random_id.random.hex}", "-", ""))
  object_ids = [
    data.azurerm_client_config.current.object_id,
    module.ecs_appsrv1_vm.vm.identity[0].principal_id,
    module.ecs_test_vm.vm.identity[0].principal_id,
    module.ecs_cgs.vm.identity[0].principal_id,
    module.onprem_vm.vm.identity[0].principal_id,
  ]
}

####################################################
# stoarge account
####################################################

# storage account

resource "azurerm_storage_account" "storage" {
  resource_group_name      = azurerm_resource_group.rg.name
  name                     = local.storage_storage_account_name
  location                 = local.ecs_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.ecs_tags
}

# container

resource "azurerm_storage_container" "storage" {
  name                  = "storage"
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

# blob

resource "azurerm_storage_blob" "storage" {
  name                   = "storage.txt"
  storage_account_name   = azurerm_storage_account.storage.name
  storage_container_name = azurerm_storage_container.storage.name
  type                   = "Block"
  source_content         = "Hello, World!"
}

# role assignment

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

resource "azurerm_key_vault" "key_vault" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.ecs_location
  name                = "${local.ecs_prefix}kv${random_id.random.hex}"
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = local.ecs_tags
}

resource "azurerm_key_vault_secret" "key_vault" {
  name         = "message"
  value        = "Hello, world!"
  key_vault_id = azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault_access_policy" "key_vault" {
  count        = length(local.object_ids)
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = local.object_ids[count.index]

  key_permissions = [
    "Get",
    "List",
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set",
  ]
}

####################################################
# output files
####################################################

locals {
  crawler_targets = [
    replace(replace(azurerm_key_vault.key_vault.vault_uri, "https://", ""), "/", ""),
    replace(replace(azurerm_storage_account.storage.primary_blob_endpoint, "https://", ""), "/", ""),
  ]
  services_files = {
    "output/crawler-targets.txt" = join("\n", local.crawler_targets)
  }
}

resource "local_file" "services_files" {
  for_each = local.services_files
  filename = each.key
  content  = each.value
}
