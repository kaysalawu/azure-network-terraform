####################################################
# Lab
####################################################

locals {
  prefix                 = "G04"
  lab_name               = "AppgwWebsocket"
  enable_diagnostics     = false
  enable_onprem_wan_link = false
  hub1_tags              = { "lab" = local.prefix, "nodeType" = "hub" }
  hub1_appgw_pip         = azurerm_public_ip.hub1_appgw_pip.ip_address
  hub1_host_server       = "server-${local.hub1_appgw_pip}.nip.io"
}

####################################################
# providers
####################################################

provider "azurerm" {
  skip_provider_registration = true
  features {}
}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.78.0"
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
      address_space = local.hub1_address_space
      subnets       = local.hub1_subnets
    }

    config_s2s_vpngw = {
      enable = false
    }

    config_p2s_vpngw = {
      enable                   = false
      ip_configuration         = []
      vpn_client_configuration = {}
    }

    config_ergw = {
      enable = false
    }

    config_firewall = {
      enable = false
    }

    config_nva = {
      enable = false
      type   = null
    }
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
  firewall_sku     = local.firewall_sku
  regions          = local.regions
  private_prefixes = local.private_prefixes
  tags             = {}
}

# vm startup scripts
#----------------------------

locals {
  vm_startup_container_dir = "/var/lib/labs"
  vm_websocket_server_init = {
    "${local.vm_startup_container_dir}/Dockerfile"       = { owner = "root", permissions = "0744", content = templatefile("./scripts/websockets/server/app/Dockerfile", {}) }
    "${local.vm_startup_container_dir}/main.py"          = { owner = "root", permissions = "0744", content = templatefile("./scripts/websockets/server/app/main.py", {}) }
    "${local.vm_startup_container_dir}/requirements.txt" = { owner = "root", permissions = "0744", content = templatefile("./scripts/websockets/server/app/requirements.txt", {}) }
  }
}

module "vm_websocket_client_init" {
  source   = "../../modules/cloud-config-gen"
  packages = ["docker.io", "docker-compose", "npm", ]
  run_commands = [
    "systemctl enable docker",
    "systemctl start docker",
    "npm install -g wscat",
  ]
}

module "vm_websocket_server_init" {
  source   = "../../modules/cloud-config-gen"
  files    = local.vm_websocket_server_init
  packages = ["docker.io", "docker-compose", "npm", ]
  run_commands = [
    "systemctl enable docker",
    "systemctl start docker",
    "npm install -g wscat",
    "cd ${local.vm_startup_container_dir}",
    "docker build -t server .",
    "docker run -d -p 8080:8080 --name server server",
    "docker run -d -p 80:80 --name nginx nginx",
  ]
}

####################################################
# addresses
####################################################

resource "azurerm_public_ip" "hub1_appgw_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}appgw-pip"
  location            = local.hub1_location
  sku                 = "Standard"
  allocation_method   = "Static"
}

####################################################
# output files
####################################################

locals {
  main_files = {
    "output/websocket-client-init.sh" = module.vm_websocket_client_init.cloud_config
    "output/server-init.sh"           = module.vm_websocket_server_init.cloud_config
  }
}

resource "local_file" "main_files" {
  for_each = local.main_files
  filename = each.key
  content  = each.value
}
