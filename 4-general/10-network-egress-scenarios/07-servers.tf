
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
  ecs_test_init_dir = "/var/lib/labs"
  ecs_no_proxy = [
    "168.63.129.16",
    "169.254.169.254",
    "127.0.0.1",
    "corp",
  ]
  ecs_test_vars = {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
  }
  ecs_test_files = {
    "${local.ecs_test_init_dir}/init/server.sh"                     = { owner = "root", permissions = "0744", content = templatefile("../../scripts/server.sh", local.ecs_test_vars) }
    "${local.ecs_test_init_dir}/test/crawler/app/crawler.sh"        = { owner = "root", permissions = "0744", content = templatefile("./scripts/crawler/app/crawler.sh", local.ecs_test_vars) }
    "${local.ecs_test_init_dir}/test/crawler/app/service_tags.py"   = { owner = "root", permissions = "0744", content = templatefile("./scripts/crawler/app/service_tags.py", local.ecs_test_vars) }
    "${local.ecs_test_init_dir}/test/crawler/app/service_access.py" = { owner = "root", permissions = "0744", content = templatefile("./scripts/crawler/app/service_access.py", local.ecs_test_vars) }
    "${local.ecs_test_init_dir}/test/crawler/app/requirements.txt"  = { owner = "root", permissions = "0744", content = templatefile("./scripts/crawler/app/requirements.txt", local.ecs_test_vars) }
  }
}

module "ecs_test_init" {
  source = "../../modules/cloud-config-gen"
  files  = local.ecs_test_files
  run_commands = [
    ". ${local.ecs_test_init_dir}/init/server.sh",
    "/bin/bash -c 'echo export http_proxy=http://${local.ecs_cgs_addr}:3128 >> /etc/environment'",
    "/bin/bash -c 'echo export https_proxy=http://${local.ecs_cgs_addr}:3128 >> /etc/environment'",
    "/bin/bash -c 'echo export ftp_proxy=http://${local.ecs_cgs_addr}:3128 >> /etc/environment'",
    "/bin/bash -c 'echo export no_proxy=${join(",", local.ecs_no_proxy)} >> /etc/environment'",
    "python3 -m venv ${local.ecs_test_init_dir}/test/crawler",
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
  appsrv_files = {
    "output/ecs-test-init.yaml" = module.ecs_test_init.cloud_config
  }
}

resource "local_file" "appsrv_files" {
  for_each = local.appsrv_files
  filename = each.key
  content  = each.value
}
