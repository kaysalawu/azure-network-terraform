
locals {
  vm_startup_container_dir = "/var/lib/azure"
  vm_websocket_server_init = {
    "${local.vm_startup_container_dir}/Dockerfile"       = { owner = "root", permissions = "0744", content = templatefile("./scripts/websockets/server/app/Dockerfile", {}) }
    "${local.vm_startup_container_dir}/main.py"          = { owner = "root", permissions = "0744", content = templatefile("./scripts/websockets/server/app/main.py", {}) }
    "${local.vm_startup_container_dir}/requirements.txt" = { owner = "root", permissions = "0744", content = templatefile("./scripts/websockets/server/app/requirements.txt", {}) }
  }
  vm_websocket_client_init = {
    "${local.vm_startup_container_dir}/Dockerfile"       = { owner = "root", permissions = "0744", content = templatefile("./scripts/websockets/client/app/Dockerfile", {}) }
    "${local.vm_startup_container_dir}/main.py"          = { owner = "root", permissions = "0744", content = templatefile("./scripts/websockets/client/app/main.py", {}) }
    "${local.vm_startup_container_dir}/requirements.txt" = { owner = "root", permissions = "0744", content = templatefile("./scripts/websockets/client/app/requirements.txt", {}) }
  }
}

####################################################
# client
####################################################

module "vm_websocket_client_init" {
  source   = "../../modules/cloud-config-gen"
  packages = ["docker.io", "docker-compose", "npm", "python3-pip", "python3-dev", "python3-venv", ]
  files    = local.vm_websocket_client_init
  run_commands = [
    "npm install -g wscat",
  ]
}

module "websocket_client_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.hub1_client_hostname}"
  computer_name   = local.hub1_client_hostname
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.vm_websocket_client_init.cloud_config)
  tags            = local.hub1_tags

  interfaces = [
    {
      name               = "${local.hub1_prefix}vm-client-nic"
      subnet_id          = module.hub1.subnets["MainSubnet"].id
      private_ip_address = local.hub1_client_addr
    },
  ]
  depends_on = [
    module.hub1
  ]
}

####################################################
# server
####################################################

module "vm_websocket_server_init" {
  source   = "../../modules/cloud-config-gen"
  files    = local.vm_websocket_server_init
  packages = ["docker.io", "docker-compose", "npm", ]
  run_commands = [
    "npm install -g wscat",
    "cd ${local.vm_startup_container_dir}",
    "docker build -t server .",
    "docker run -d -p 8080:8080 --name server server",
    "docker run -d -p 80:80 --name nginx nginx",
  ]
}

module "websocket_server_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.hub1_server_hostname}"
  computer_name   = local.hub1_server_hostname
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.vm_websocket_server_init.cloud_config)
  tags            = local.hub1_tags

  interfaces = [
    {
      name               = "${local.hub1_prefix}vm-server-nic"
      subnet_id          = module.hub1.subnets["MainSubnet"].id
      private_ip_address = local.hub1_server_addr
    },
  ]
  depends_on = [
    module.hub1
  ]
}

####################################################
# output files
####################################################

locals {
  workload_files = {
    "output/websocket-client-init.sh" = module.vm_websocket_client_init.cloud_config
    "output/server-init.sh"           = module.vm_websocket_server_init.cloud_config
  }
}

resource "local_file" "workload_files" {
  for_each = local.workload_files
  filename = each.key
  content  = each.value
}

