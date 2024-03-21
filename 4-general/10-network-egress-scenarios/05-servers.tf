
locals {
  ecs_init_dir = "/var/lib/azure"
  ecs_crawler_vars = {
    RESOURCE_GROUP             = azurerm_resource_group.rg.name
    STORAGE_ACCOUNT_NAME       = azurerm_storage_account.storage.name
    KEY_VAULT_NAME             = azurerm_key_vault.key_vault.name
    SERVICE_TAGS_DOWNLOAD_LINK = "https://download.microsoft.com/download/7/1/D/71D86715-5596-4529-9B13-DA13A5DE5B63/ServiceTags_Public_20240318.json"
  }
  ecs_crawler_files = {
    "${local.ecs_init_dir}/crawler/app/crawler.sh"        = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/crawler.sh", local.ecs_crawler_vars) }
    "${local.ecs_init_dir}/crawler/app/service_tags.py"   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/service_tags.py", local.ecs_crawler_vars) }
    "${local.ecs_init_dir}/crawler/app/service_access.py" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/service_access.py", local.ecs_crawler_vars) }
    "${local.ecs_init_dir}/crawler/app/requirements.txt"  = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/requirements.txt", local.ecs_crawler_vars) }
  }
  ecs_server_vars = {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
  }
  ecs_server_files = {
    "${local.ecs_init_dir}/init/server.sh" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/server.sh", local.ecs_server_vars) }
  }
}

####################################################
# customer gateway server (cgs)
####################################################

locals {
  ecs_cgs_startup = templatefile("../../scripts/unbound/unbound.sh", local.ecs_cgs_vars)
  ecs_cgs_vars = {
    ONPREM_LOCAL_RECORDS = local.ecs_local_records
    REDIRECTED_HOSTS     = local.ecs_redirected_hosts
    FORWARD_ZONES        = local.ecs_forward_zones
    TARGETS              = local.vm_script_targets
    ACCESS_CONTROL_PREFIXES = concat(
      local.private_prefixes,
      ["127.0.0.0/8", "35.199.192.0/19", ]
    )
  }
  ecs_cgs_files = merge(
    local.ecs_crawler_files,
    local.ecs_server_files,
    {
      "${local.ecs_init_dir}/unbound/Dockerfile"         = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/Dockerfile", {}) }
      "${local.ecs_init_dir}/unbound/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/docker-compose.yml", {}) }
      "${local.ecs_init_dir}/unbound/setup-unbound.sh"   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/setup-unbound.sh", local.ecs_cgs_vars) }
      "/etc/unbound/unbound.conf"                        = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/unbound.conf", local.ecs_cgs_vars) }

      "${local.ecs_init_dir}/squid/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/docker-compose.yml", local.ecs_cgs_vars) }
      "${local.ecs_init_dir}/squid/setup-squid.sh"     = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/setup-squid.sh", local.ecs_cgs_vars) }
      "/etc/squid/blocked_sites"                       = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/blocked_sites", local.ecs_cgs_vars) }
      "/etc/squid/squid.conf"                          = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/squid.conf", local.ecs_cgs_vars) }
    }
  )
  ecs_local_records = [
    { name = lower(local.ecs_webd1_fqdn), record = local.ecs_webd1_addr },
    { name = lower(local.ecs_webd2_fqdn), record = local.ecs_webd2_addr },
    { name = lower(local.ecs_appsrv1_fqdn), record = local.ecs_appsrv1_addr },
    { name = lower(local.ecs_appsrv2_fqdn), record = local.ecs_appsrv2_addr },
    { name = lower(local.ecs_cgs_fqdn), record = local.ecs_cgs_addr },
    { name = lower(local.ecs_webd_ilb_fqdn), record = local.ecs_webd_ilb_addr },
  ]
  ecs_redirected_hosts = []
  ecs_forward_zones = [
    { zone = ".", targets = [local.azuredns, ] },
  ]
}

module "ecs_cgs_init" {
  source   = "../../modules/cloud-config-gen"
  packages = ["docker.io", "docker-compose", "dnsutils", "net-tools", ]
  files    = local.ecs_cgs_files
  run_commands = [
    ". ${local.ecs_init_dir}/init/server.sh",
    ". ${local.ecs_init_dir}/unbound/setup-unbound.sh",
    ". ${local.ecs_init_dir}/squid/setup-squid.sh",
    "docker-compose -f ${local.ecs_init_dir}/unbound/docker-compose.yml up -d",
    "docker-compose -f ${local.ecs_init_dir}/squid/docker-compose.yml up -d",
    "python3 -m venv ${local.ecs_init_dir}/crawler",
  ]
}

module "ecs_cgs" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.ecs_cgs_hostname}"
  computer_name   = local.ecs_cgs_hostname
  location        = local.ecs_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.ecs_cgs_init.cloud_config)
  tags            = local.ecs_tags

  interfaces = [
    {
      name               = "${local.ecs_prefix}cgs-prod-nic"
      subnet_id          = module.ecs.subnets["ProductionSubnet"].id
      private_ip_address = local.ecs_cgs_addr
    },
  ]
}

####################################################
# app servers
####################################################

module "ecs_appsrv1_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.ecs_appsrv1_hostname}"
  computer_name   = local.ecs_appsrv1_hostname
  location        = local.ecs_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.vm_startup)
  tags            = local.ecs_tags

  interfaces = [
    {
      name               = "${local.ecs_prefix}appsrv1-nic"
      subnet_id          = module.ecs.subnets["ProductionSubnet"].id
      private_ip_address = local.ecs_appsrv1_addr
    },
  ]
  depends_on = [
    module.ecs
  ]
}

# module "appsrv2_vm" {
#   source          = "../../modules/virtual-machine-linux"
#   resource_group  = azurerm_resource_group.rg.name
#   name            = "${local.prefix}-${local.ecs_appsrv2_hostname}"
#   computer_name   = local.ecs_appsrv2_hostname
#   location        = local.ecs_location
#   storage_account = module.common.storage_accounts["region1"]
#   custom_data     = base64encode(local.vm_startup)
#   tags            = local.ecs_tags

#   interfaces = [
#     {
#       name               = "${local.ecs_prefix}appsrv2-nic"
#       subnet_id          = module.ecs.subnets["ProductionSubnet"].id
#       private_ip_address = local.ecs_appsrv2_addr
#       create_public_ip   = true
#     },
#   ]
#   depends_on = [
#     module.ecs
#   ]
# }

####################################################
# test servers (proxied internet egress)
####################################################

locals {
  ecs_no_proxy = [
    "168.63.129.16",
    "169.254.169.254",
    "127.0.0.1",
    "corp",
  ]
  ecs_test_files = merge(
    local.ecs_crawler_files,
    local.ecs_server_files,
  )
}

module "ecs_test_init" {
  source = "../../modules/cloud-config-gen"
  files  = local.ecs_test_files
  run_commands = [
    ". ${local.ecs_init_dir}/init/server.sh",
    "/bin/bash -c 'echo export http_proxy=http://${local.ecs_cgs_addr}:3128 >> /etc/environment'",
    "/bin/bash -c 'echo export https_proxy=http://${local.ecs_cgs_addr}:3128 >> /etc/environment'",
    "/bin/bash -c 'echo export ftp_proxy=http://${local.ecs_cgs_addr}:3128 >> /etc/environment'",
    "/bin/bash -c 'echo export no_proxy=${join(",", local.ecs_no_proxy)} >> /etc/environment'",
    "python3 -m venv ${local.ecs_init_dir}/crawler",
  ]
}

module "ecs_test_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.ecs_test_hostname}"
  computer_name   = local.ecs_test_hostname
  location        = local.ecs_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.ecs_test_init.cloud_config)
  tags            = local.ecs_tags

  interfaces = [
    {
      name      = "${local.ecs_prefix}test-nic"
      subnet_id = module.ecs.subnets["ProductionSubnet"].id
    },
  ]
  depends_on = [
    module.ecs
  ]
}

####################################################
# output files
####################################################

locals {
  ecs_files = {
    "output/ecs-cgs-init.yaml"  = module.ecs_cgs_init.cloud_config
    "output/ecs-test-init.yaml" = module.ecs_test_init.cloud_config
  }
}

resource "local_file" "ecs_files" {
  for_each = local.ecs_files
  filename = each.key
  content  = each.value
}
