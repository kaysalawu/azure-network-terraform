
####################################################
# server 1
####################################################

locals {
  server1_crawler_vars = merge(local.base_crawler_vars, {
    VNET_NAME   = module.hub.vnet.name
    SUBNET_NAME = module.hub.subnets["ProductionSubnet"].name
    VM_NAME     = "${local.prefix}-${local.hub_server1_hostname}"
  })
  server1_crawler_files = {
    "${local.init_dir}/crawler/app/crawler.sh"       = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/crawler.sh", local.server1_crawler_vars) }
    "${local.init_dir}/crawler/app/service_tags.py"  = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/service_tags.py", local.server1_crawler_vars) }
    "${local.init_dir}/crawler/app/requirements.txt" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/requirements.txt", local.server1_crawler_vars) }
  }
  hub_server1_files = merge(
    local.vm_init_files,
    local.vm_startup_init_files,
    local.server1_crawler_files,
  )
}

module "hub_server1_init" {
  source = "../../modules/cloud-config-gen"
  files  = local.hub_server1_files
  run_commands = [
    ". ${local.init_dir}/init/startup.sh",
    "python3 -m venv ${local.init_dir}/crawler",
  ]
}

module "hub_server1_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.hub_server1_hostname}"
  computer_name   = local.hub_server1_hostname
  location        = local.hub_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.hub_server1_init.cloud_config)
  tags            = local.hub_tags

  interfaces = [
    {
      name               = "${local.hub_prefix}server1-nic"
      subnet_id          = module.hub.subnets["ProductionSubnet"].id
      private_ip_address = local.hub_server1_addr
      # create_public_ip   = true
    },
  ]
  depends_on = [
    module.hub
  ]
}

####################################################
# server 2 (using proxy)
####################################################

locals {
  hub_server2_no_proxy = [
    "168.63.129.16",
    "169.254.169.254",
    "127.0.0.1",
    "corp",
  ]
  server2_crawler_vars = merge(local.base_crawler_vars, {
    VNET_NAME   = module.hub.vnet.name
    SUBNET_NAME = module.hub.subnets["ProductionSubnet"].name
    VM_NAME     = "${local.prefix}-${local.hub_server2_hostname}"
  })
  server2_crawler_files = {
    "${local.init_dir}/crawler/app/crawler.sh"       = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/crawler.sh", local.server2_crawler_vars) }
    "${local.init_dir}/crawler/app/service_tags.py"  = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/service_tags.py", local.server2_crawler_vars) }
    "${local.init_dir}/crawler/app/requirements.txt" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/requirements.txt", local.server2_crawler_vars) }
  }
  hub_server2_files = merge(
    local.vm_init_files,
    local.vm_startup_init_files,
    local.server2_crawler_files,
  )
}

module "hub_server2_init" {
  source = "../../modules/cloud-config-gen"
  files  = local.hub_server2_files
  run_commands = [
    ". ${local.init_dir}/init/startup.sh",
    "/bin/bash -c 'echo export http_proxy=http://${local.hub_proxy_addr}:3128 >> /etc/environment'",
    "/bin/bash -c 'echo export https_proxy=http://${local.hub_proxy_addr}:3128 >> /etc/environment'",
    "/bin/bash -c 'echo export ftp_proxy=http://${local.hub_proxy_addr}:3128 >> /etc/environment'",
    "/bin/bash -c 'echo export no_proxy=${join(",", local.hub_server2_no_proxy)} >> /etc/environment'",
    "python3 -m venv ${local.init_dir}/crawler",
  ]
}

module "hub_server2_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.hub_server2_hostname}"
  computer_name   = local.hub_server2_hostname
  location        = local.hub_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.hub_server2_init.cloud_config)
  tags            = local.hub_tags

  interfaces = [
    {
      name               = "${local.hub_prefix}server2-nic"
      subnet_id          = module.hub.subnets["ProductionSubnet"].id
      private_ip_address = local.hub_server2_addr
      # create_public_ip   = true
    },
  ]
  depends_on = [
    module.hub
  ]
}

####################################################
# output files
####################################################

locals {
  hub_server_output_files = {
    "output/server1-init.yaml"  = module.hub_server1_init.cloud_config
    "output/server2-init.yaml"  = module.hub_server2_init.cloud_config
    "output/server1-crawler.sh" = templatefile("../../scripts/init/crawler/app/crawler.sh", local.server1_crawler_vars)
    "output/server2-crawler.sh" = templatefile("../../scripts/init/crawler/app/crawler.sh", local.server2_crawler_vars)
  }
}

resource "local_file" "hub_server_output_files" {
  for_each = local.hub_server_output_files
  filename = each.key
  content  = each.value
}
