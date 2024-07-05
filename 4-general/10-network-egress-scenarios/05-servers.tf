
####################################################
# common
####################################################

locals {
  hub1_server_files = merge(
    local.vm_init_files,
    local.probe_startup_init_files,
    local.hub1_crawler_files,
  )
  hub1_server2_no_proxy = [
    "168.63.129.16",
    "169.254.169.254",
    "127.0.0.1",
    "corp",
  ]
}

module "hub1_server_init" {
  source   = "../../modules/cloud-config-gen"
  packages = ["docker.io", "docker-compose", ]
  files    = local.hub1_server_files
  run_commands = [
    ". ${local.init_dir}/init/startup.sh",
    "docker-compose -f ${local.init_dir}/fastapi/docker-compose-app1-80.yml up -d",
    "docker-compose -f ${local.init_dir}/fastapi/docker-compose-app2-8080.yml up -d",
  ]
}

####################################################
# server 1
####################################################

module "hub1_server1_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.hub1_server1_hostname}"
  computer_name   = local.hub1_server1_hostname
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  dns_servers     = [local.hub1_proxy_addr, ]
  custom_data     = base64encode(module.hub1_server_init.cloud_config)
  tags = merge(
    local.hub1_tags,
    local.hub1_crawler_vars,
    {
      VNET_NAME   = module.hub1.vnet.name
      SUBNET_NAME = module.hub1.subnets["ProductionSubnet"].name
    }
  )

  interfaces = [
    {
      name               = "${local.hub1_prefix}server1-nic"
      subnet_id          = module.hub1.subnets["ProductionSubnet"].id
      private_ip_address = local.hub1_server1_addr
    },
  ]
  depends_on = [
    time_sleep.hub1_proxy,
  ]
}

####################################################
# server 2 (using proxy)
####################################################

module "hub1_server2_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.hub1_server2_hostname}"
  computer_name   = local.hub1_server2_hostname
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  dns_servers     = [local.hub1_proxy_addr, ]
  custom_data     = base64encode(module.hub1_server_init.cloud_config)
  tags = merge(
    local.hub1_tags,
    local.hub1_crawler_vars,
    {
      VNET_NAME   = module.hub1.vnet.name
      SUBNET_NAME = module.hub1.subnets["ProductionSubnet"].name
    }
  )

  interfaces = [
    {
      name               = "${local.hub1_prefix}server2-nic"
      subnet_id          = module.hub1.subnets["ProductionSubnet"].id
      private_ip_address = local.hub1_server2_addr
    },
  ]
  depends_on = [
    time_sleep.hub1_proxy,
  ]
}

####################################################
# udr
####################################################

# production

resource "time_sleep" "hub1_production_udr" {
  create_duration = "2m"
  depends_on = [
    time_sleep.hub1_proxy,
    module.hub1_server1_vm,
    module.hub1_server2_vm,
  ]
}

module "hub1_production_udr" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.prefix}-hub1-production"
  location       = local.hub1_location
  subnet_ids = [
    module.hub1.subnets["ProductionSubnet"].id
  ]
  routes = [
    {
      name           = "azure-services"
      address_prefix = local.service_tags
      next_hop_type  = "Internet"
    },
  ]

  depends_on = [
    time_sleep.hub1_production_udr
  ]
}

####################################################
# output files
####################################################

locals {
  hub1_server_output_files = {
    "output/server-init.yaml" = module.hub1_server_init.cloud_config
    "output/hub1-crawler.sh"  = templatefile("../../scripts/init/crawler/app/crawler.sh", local.hub1_crawler_vars)
  }
}

resource "local_file" "hub1_server_output_files" {
  for_each = local.hub1_server_output_files
  filename = each.key
  content  = each.value
}
