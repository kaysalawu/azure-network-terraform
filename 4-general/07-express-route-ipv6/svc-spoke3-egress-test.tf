
locals {
  spoke3_test_storage_account_name   = lower(replace("${local.spoke3_prefix}${random_id.random.hex}", "-", ""))
  spoke3_test_storage_container_name = "storage"
  spoke3_test_storage_blob_name      = "storage.txt"
  spoke3_test_storage_blob_content   = "Hello, World!"
  spoke3_test_storage_blob_url       = "https://${local.spoke3_test_storage_account_name}.blob.core.windows.net/storage/storage.txt"

  spoke3_test_key_vault_secret_name  = "message"
  spoke3_test_key_vault_name         = lower("${local.spoke3_prefix}kv${random_id.random.hex}")
  spoke3_test_key_vault_secret_value = "Hello, World!"
  spoke3_test_key_vault_secret_url   = "https://${local.spoke3_test_key_vault_name}.vault.azure.net/secrets/${local.spoke3_test_key_vault_secret_name}"

  spoke3_test_object_ids       = [module.spoke3_test.vm.identity[0].principal_id, ]
  spoke3_test_role_definitions = ["Network Contributor", ]

  spoke3_test_role_assignments = flatten([
    for oid in local.spoke3_test_object_ids : [
      for role in local.spoke3_test_role_definitions : {
        id   = "${oid}-${role}"
        oid  = oid
        role = role
      }
    ]
  ])

  spoke3_test_assignment_map = { for ra in local.spoke3_test_role_assignments : ra.id => {
    "principal_id" : ra.oid,
    "role_definition" : ra.role
  } }
}


resource "azurerm_role_assignment" "spoke3_test_combined_role_assignment" {
  count                = length(local.spoke3_test_role_assignments)
  scope                = azurerm_resource_group.rg.id
  role_definition_name = local.spoke3_test_role_assignments[count.index].role
  principal_id         = local.spoke3_test_role_assignments[count.index].oid
}

####################################################
# storage
####################################################

# account

resource "azurerm_storage_account" "spoke3_test_storage" {
  resource_group_name      = azurerm_resource_group.rg.name
  name                     = local.spoke3_test_storage_account_name
  location                 = local.spoke3_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.spoke3_tags
}

# container

resource "azurerm_storage_container" "spoke3_test_storage" {
  name                  = local.spoke3_test_storage_container_name
  storage_account_name  = azurerm_storage_account.spoke3_test_storage.name
  container_access_type = "private"
}

# blob

resource "azurerm_storage_blob" "spoke3_test_storage" {
  name                   = "storage.txt"
  storage_account_name   = azurerm_storage_account.spoke3_test_storage.name
  storage_container_name = azurerm_storage_container.spoke3_test_storage.name
  type                   = "Block"
  source_content         = local.spoke3_test_storage_blob_content
}

# roles

resource "azurerm_role_assignment" "spoke3_test_storage" {
  count                = length(local.spoke3_test_object_ids)
  scope                = azurerm_storage_account.spoke3_test_storage.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = local.spoke3_test_object_ids[count.index]
}

resource "azurerm_role_assignment" "spoke3_test_blob" {
  count                = length(local.spoke3_test_object_ids)
  scope                = azurerm_storage_account.spoke3_test_storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = local.spoke3_test_object_ids[count.index]
}

####################################################
# key vault
####################################################

# vault

resource "azurerm_key_vault" "spoke3_test_key_vault" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.spoke3_location
  name                = "${local.spoke3_prefix}kv${random_id.random.hex}"
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  tags                = local.spoke3_tags
}

# policies

resource "azurerm_key_vault_access_policy" "spoke3_test_current" {
  key_vault_id = azurerm_key_vault.spoke3_test_key_vault.id
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

resource "azurerm_key_vault_access_policy" "spoke3_test_key_vault" {
  count        = length(local.spoke3_test_object_ids)
  key_vault_id = azurerm_key_vault.spoke3_test_key_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = local.spoke3_test_object_ids[count.index]

  key_permissions    = ["Get", "List", ]
  secret_permissions = ["Get", "List", "Set", ]
}

resource "time_sleep" "spoke3_test_key_vault" {
  create_duration = "30s"
  depends_on = [
    azurerm_key_vault_access_policy.spoke3_test_current,
    azurerm_key_vault_access_policy.spoke3_test_key_vault,
  ]
}

# secret

resource "azurerm_key_vault_secret" "spoke3_test_key_vault" {
  name         = local.spoke3_test_key_vault_secret_name
  value        = local.spoke3_test_key_vault_secret_value
  key_vault_id = azurerm_key_vault.spoke3_test_key_vault.id
  depends_on = [
    time_sleep.spoke3_test_key_vault,
  ]
}

####################################################
# workload
####################################################

locals {
  spoke3_test_base_crawler_vars = {
    MANAGEMENT_URL             = "https://management.azure.com/subscriptions?api-version=2020-01-01"
    SERVICE_TAGS_DOWNLOAD_LINK = "https://download.microsoft.com/download/7/1/D/71D86715-5596-4529-9B13-DA13A5DE5B63/ServiceTags_Public_20240318.json"
    RESOURCE_GROUP             = azurerm_resource_group.rg.name
    LOCATION                   = local.spoke3_location

    STORAGE_ACCOUNT_NAME   = local.spoke3_test_storage_account_name
    STORAGE_CONTAINER_NAME = local.spoke3_test_storage_container_name
    STORAGE_BLOB_URL       = local.spoke3_test_storage_blob_url
    STORAGE_BLOB_NAME      = local.spoke3_test_storage_blob_name
    STORAGE_BLOB_CONTENT   = local.spoke3_test_storage_blob_content

    KEY_VAULT_NAME         = local.spoke3_test_key_vault_name
    KEY_VAULT_SECRET_NAME  = local.spoke3_test_key_vault_secret_name
    KEY_VAULT_SECRET_URL   = local.spoke3_test_key_vault_secret_url
    KEY_VAULT_SECRET_VALUE = local.spoke3_test_key_vault_secret_value
  }
  spoke3_test_crawler_vars = merge(local.spoke3_test_base_crawler_vars, {
    VNET_NAME   = module.spoke3.vnet.name
    SUBNET_NAME = module.spoke3.subnets["TestSubnet"].name
    VM_NAME     = "Spoke3Test"
  })
  spoke3_test_crawler_files = {
    "${local.init_dir}/crawler/app/crawler.sh"       = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/crawler.sh", local.spoke3_test_crawler_vars) }
    "${local.init_dir}/crawler/app/service_tags.py"  = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/service_tags.py", local.spoke3_test_crawler_vars) }
    "${local.init_dir}/crawler/app/requirements.txt" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/requirements.txt", local.spoke3_test_crawler_vars) }
  }
}

module "spoke3_test_init" {
  source = "../../modules/cloud-config-gen"
  files = merge(
    local.vm_init_files,
    local.vm_startup_init_files,
    local.spoke3_test_crawler_files,
  )
  run_commands = [
    "bash ${local.init_dir}/init/startup.sh",
    "python3 -m venv ${local.init_dir}/crawler",
  ]
}

module "spoke3_test" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-Spoke3Test"
  computer_name   = "Spoke3Test"
  location        = local.spoke3_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.spoke3_test_init.cloud_config)
  tags            = local.spoke3_tags

  enable_ipv6 = local.enable_ipv6
  interfaces = [
    {
      name             = "${local.spoke3_prefix}test-nic"
      subnet_id        = module.spoke3.subnets["TestSubnet"].id
      create_public_ip = true
    },
  ]
  depends_on = [
    time_sleep.spoke3,
  ]
}

####################################################
# output files
####################################################

locals {
  spokes_test_files = {
    "output/spoke3-test-cloud-config.yml" = module.spoke3_test_init.cloud_config
  }
}

resource "local_file" "spokes_test_files" {
  for_each = local.spokes_test_files
  filename = each.key
  content  = each.value
}
