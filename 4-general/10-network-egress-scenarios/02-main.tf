####################################################
# Lab
####################################################

locals {
  prefix                   = "Lab10"
  lab_name                 = "NetworkEgress"
  enable_diagnostics       = true
  enable_service_endpoints = false
  enable_lb_snat_outbound  = false
  enable_service_tags      = false

  storage_storage_account_name = lower(replace("${local.hub_prefix}${random_id.random.hex}", "-", ""))
  storage_container_name       = "storage"
  storage_blob_name            = "storage.txt"
  storage_blob_content         = "Hello, World!"
  storage_blob_url             = "https://${local.storage_storage_account_name}.blob.core.windows.net/storage/storage.txt"

  key_vault_secret_name  = "message"
  key_vault_name         = lower("${local.hub_prefix}kv${random_id.random.hex}")
  key_vault_secret_value = "Hello, World!"
  key_vault_secret_url   = "https://${local.key_vault_name}.vault.azure.net/secrets/${local.key_vault_secret_name}"

  hub_tags = { "lab" = local.prefix, "nodeType" = "hub" }
}

resource "random_id" "random" {
  byte_length = 2
}

data "azurerm_client_config" "current" {}

####################################################
# providers
####################################################

provider "azurerm" {
  skip_provider_registration = true
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azapi" {}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.78.0"
    }
    azapi = {
      source = "azure/azapi"
    }
  }
}

####################################################
# network features
####################################################

locals {
  regions = {
    "region1" = { name = local.region1, dns_zone = local.region1_dns_zone }
  }
  hub_features = {
    config_vnet = {
      address_space                = local.hub_address_space
      subnets                      = local.hub_subnets
      enable_private_dns_resolver  = false
      enable_ars                   = false
      ruleset_dns_forwarding_rules = {}
      nat_gateway_subnet_names = [
        "ProductionSubnet",
      ]
    }
    config_s2s_vpngw = { enable = false }
    config_p2s_vpngw = { enable = false }
    config_ergw      = { enable = false }
    config_firewall  = { enable = false }
    config_nva       = { enable = false }
  }
}

####################################################
# common resources
####################################################

# resource group

resource "azurerm_resource_group" "rg" {
  name     = "${local.prefix}_${local.lab_name}_RG"
  location = local.default_region
  tags = {
    prefix   = local.prefix
    lab_name = local.lab_name
  }
}

module "common" {
  source           = "../../modules/common"
  resource_group   = azurerm_resource_group.rg.name
  env              = "common"
  prefix           = local.prefix
  regions          = local.regions
  private_prefixes = local.private_prefixes
  tags             = {}
}

# vm startup scripts
#----------------------------

locals {
  init_dir                  = "/var/lib/azure"
  hub_vpngw_asn             = "65515"
  vm_script_targets_region1 = []
  vm_script_targets_misc    = [{ name = "internet", dns = "contoso.com", ip = "contoso.com" }, ]
  vm_script_targets = concat(
    local.vm_script_targets_region1,
    local.vm_script_targets_misc,
  )
  vm_startup = templatefile("../../scripts/server.sh", {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
    ENABLE_TRAFFIC_GEN        = false
  })
  probe_init_vars = {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
  }
  vm_init_vars = {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
  }
  base_crawler_vars = {
    MANAGEMENT_URL             = "https://management.azure.com/subscriptions?api-version=2020-01-01"
    SERVICE_TAGS_DOWNLOAD_LINK = "https://download.microsoft.com/download/7/1/D/71D86715-5596-4529-9B13-DA13A5DE5B63/ServiceTags_Public_20240318.json"
    RESOURCE_GROUP             = azurerm_resource_group.rg.name
    LOCATION                   = local.hub_location

    STORAGE_ACCOUNT_NAME   = local.storage_storage_account_name
    STORAGE_CONTAINER_NAME = local.storage_container_name
    STORAGE_BLOB_URL       = local.storage_blob_url
    STORAGE_BLOB_NAME      = local.storage_blob_name
    STORAGE_BLOB_CONTENT   = local.storage_blob_content

    KEY_VAULT_NAME         = local.key_vault_name
    KEY_VAULT_SECRET_NAME  = local.key_vault_secret_name
    KEY_VAULT_SECRET_URL   = local.key_vault_secret_url
    KEY_VAULT_SECRET_VALUE = local.key_vault_secret_value
  }
  vm_init_files = {
    "${local.init_dir}/fastapi/docker-compose-app1-80.yml"   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/docker-compose-app1-80.yml", {}) }
    "${local.init_dir}/fastapi/docker-compose-app2-8080.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/docker-compose-app2-8080.yml", {}) }
    "${local.init_dir}/fastapi/app/app/Dockerfile"           = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/Dockerfile", {}) }
    "${local.init_dir}/fastapi/app/app/_app.py"              = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/_app.py", {}) }
    "${local.init_dir}/fastapi/app/app/main.py"              = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/main.py", {}) }
    "${local.init_dir}/fastapi/app/app/requirements.txt"     = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/requirements.txt", {}) }
  }
  vm_startup_init_files = {
    "${local.init_dir}/init/startup.sh" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/startup.sh", local.vm_init_vars) }
  }
  probe_startup_init_files = {
    "${local.init_dir}/init/startup.sh" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/startup.sh", local.probe_init_vars) }
  }
}

module "vm_cloud_init" {
  source = "../../modules/cloud-config-gen"
  files = merge(
    local.vm_init_files,
    local.vm_startup_init_files
  )
  packages = [
    "docker.io", "docker-compose", #npm,
  ]
  run_commands = [
    "systemctl enable docker",
    "systemctl start docker",
    "bash ${local.init_dir}/init/startup.sh",
    "docker-compose -f ${local.init_dir}/fastapi/docker-compose-app1-80.yml up -d",
    "docker-compose -f ${local.init_dir}/fastapi/docker-compose-app2-8080.yml up -d",
  ]
}

module "probe_vm_cloud_init" {
  source = "../../modules/cloud-config-gen"
  files = merge(
    local.vm_init_files,
    local.probe_startup_init_files,
  )
  packages = [
    "docker.io", "docker-compose", #npm,
  ]
  run_commands = [
    "systemctl enable docker",
    "systemctl start docker",
    "bash ${local.init_dir}/init/startup.sh",
    "docker-compose -f ${local.init_dir}/fastapi/docker-compose-app1-80.yml up -d",
    "docker-compose -f ${local.init_dir}/fastapi/docker-compose-app2-8080.yml up -d",
  ]
}

####################################################
# output files
####################################################

locals {
  main_files = {
    "output/server.sh"              = local.vm_startup
    "output/startup.sh"             = templatefile("../../scripts/startup.sh", local.vm_init_vars)
    "output/probe-cloud-config.yml" = module.probe_vm_cloud_init.cloud_config
    "output/vm-cloud-config.yml"    = module.vm_cloud_init.cloud_config
  }
}

resource "local_file" "main_files" {
  for_each = local.main_files
  filename = each.key
  content  = each.value
}
