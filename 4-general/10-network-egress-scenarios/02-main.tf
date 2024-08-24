####################################################
# Lab
####################################################

locals {
  prefix                   = "Lab10"
  lab_name                 = "NetworkEgress"
  enable_diagnostics       = true
  enable_service_endpoints = false
  enable_lb_snat_outbound  = false
  enable_service_tags      = true
  enable_vnet_flow_logs    = true

  storage_storage_account_name = lower(replace("${local.hub1_prefix}${random_id.random.hex}", "-", ""))
  storage_container_name       = "storage"
  storage_blob_name            = "storage.txt"
  storage_blob_content         = "Hello, World!"
  storage_blob_url             = "https://${local.storage_storage_account_name}.blob.core.windows.net/storage/storage.txt"

  key_vault_secret_name  = "message"
  key_vault_name         = lower("${local.hub1_prefix}kv${random_id.random.hex}")
  key_vault_secret_value = "Hello, World!"
  key_vault_secret_url   = "https://${local.key_vault_name}.vault.azure.net/secrets/${local.key_vault_secret_name}"

  hub1_tags = { "lab" = local.prefix, "nodeType" = "hub" }
}

resource "random_id" "random" {
  byte_length = 2
}

data "azurerm_client_config" "current" {}

####################################################
# providers
####################################################

provider "azurerm" {
  resource_provider_registrations = "none"
  subscription_id                 = var.subscription_id
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
  hub1_features = {
    config_vnet = {
      address_space               = local.hub1_address_space
      subnets                     = local.hub1_subnets
      enable_private_dns_resolver = false
      enable_ars                  = false
      enable_vnet_flow_logs       = local.enable_vnet_flow_logs
      ruleset_dns_forwarding_rules = {

      }
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
  init_dir       = "/var/lib/azure"
  hub1_vpngw_asn = "65515"
  vm_script_targets_region1 = [
    { name = "proxy   ", dns = lower(local.hub1_proxy_fqdn), ipv4 = local.hub1_proxy_addr, probe = true },
    { name = "proxy   ", dns = lower(local.hub1_server1_fqdn), ipv4 = local.hub1_server1_addr, probe = true },
    { name = "proxy   ", dns = lower(local.hub1_server2_fqdn), ipv4 = local.hub1_server2_addr, probe = true },
  ]
  vm_script_targets_misc = [
    { name = "internet", dns = "icanhazip.com", ipv4 = "icanhazip.com", ipv6 = "icanhazip.com" },
    { name = "storage", dns = local.storage_blob_url, ping = false, probe = true },
  ]
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
  vm_init_vars = {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
  }
  probe_init_vars = {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
  }
  hub1_crawler_vars = {
    MANAGEMENT_URL         = "https://management.azure.com/subscriptions?api-version=2020-01-01"
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
  hub1_proxy_vars = {
    ONPREM_LOCAL_RECORDS = local.hub1_local_records
    REDIRECTED_HOSTS     = local.hub1_redirected_hosts
    FORWARD_ZONES        = local.hub1_forward_zones
    TARGETS              = local.vm_script_targets
    ACCESS_CONTROL_PREFIXES = concat(
      local.private_prefixes,
      ["127.0.0.0/8", "35.199.192.0/19", ]
    )
  }
  hub1_proxy_files = merge(
    local.vm_init_files,
    local.probe_startup_init_files,
    local.hub1_crawler_files,
    {
      "${local.init_dir}/unbound/Dockerfile"         = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/Dockerfile", {}) }
      "${local.init_dir}/unbound/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/docker-compose.yml", {}) }
      "${local.init_dir}/unbound/setup-unbound.sh"   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/setup-unbound.sh", local.hub1_proxy_vars) }
      "/etc/unbound/unbound.conf"                    = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/unbound.conf", local.hub1_proxy_vars) }

      "${local.init_dir}/squid/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/docker-compose.yml", local.hub1_proxy_vars) }
      "${local.init_dir}/squid/setup-squid.sh"     = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/setup-squid.sh", local.hub1_proxy_vars) }
      "/etc/squid/blocked_sites"                   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/blocked_sites", local.hub1_proxy_vars) }
      "/etc/squid/squid.conf"                      = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/squid.conf", local.hub1_proxy_vars) }
    }
  )
  vm_startup_init_files = {
    "${local.init_dir}/init/startup.sh" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/startup.sh", local.vm_init_vars) }
  }
  probe_startup_init_files = {
    "${local.init_dir}/init/startup.sh" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/startup.sh", local.probe_init_vars) }
  }
  vm_init_files = {
    "${local.init_dir}/fastapi/docker-compose-app1-80.yml"   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/docker-compose-app1-80.yml", {}) }
    "${local.init_dir}/fastapi/docker-compose-app2-8080.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/docker-compose-app2-8080.yml", {}) }
    "${local.init_dir}/fastapi/app/app/Dockerfile"           = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/Dockerfile", {}) }
    "${local.init_dir}/fastapi/app/app/_app.py"              = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/_app.py", {}) }
    "${local.init_dir}/fastapi/app/app/main.py"              = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/main.py", {}) }
    "${local.init_dir}/fastapi/app/app/requirements.txt"     = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/fastapi/app/app/requirements.txt", {}) }
  }
  hub1_crawler_files = {
    "${local.init_dir}/crawler/app/crawler.sh"       = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/crawler.sh", {}) }
    "${local.init_dir}/crawler/app/service_tags.py"  = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/service_tags.py", {}) }
    "${local.init_dir}/crawler/app/requirements.txt" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/requirements.txt", {}) }
  }

  hub1_local_records = [
    { name = lower(local.hub1_server1_fqdn), record = local.hub1_server1_addr },
    { name = lower(local.hub1_server2_fqdn), record = local.hub1_server2_addr },
    { name = lower(local.hub1_proxy_fqdn), record = local.hub1_proxy_addr },
  ]
  hub1_redirected_hosts = []
  hub1_forward_zones = [
    { zone = ".", targets = [local.azuredns, ] },
  ]
}

module "vm_cloud_init" {
  source = "../../modules/cloud-config-gen"
  files = merge(
    local.vm_init_files,
    local.vm_startup_init_files
  )
  packages = [
    "docker.io", "docker-compose",
  ]
  run_commands = [
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
    "docker.io", "docker-compose",
  ]
  run_commands = [
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
