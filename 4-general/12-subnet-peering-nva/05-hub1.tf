
/*
Overview
--------
This template creates hub1 vnet from the base module.
Extra configs defined in local variable "hub1_features" of "main.tf" to enable:
  - VPN gateway, ExpressRoute gateway
  - Azure Firewall and/or NVA
  - Private DNS zone for the hub
  - Private DNS Resolver and ruleset for onprem, cloud and PrivateLink DNS resolution
It also deploys a simple web server VM in the hub.
NSGs are assigned to selected subnets.
*/

####################################################
# vnet
####################################################

module "hub1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.hub1_prefix, "-")
  env             = "prod"
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.hub1_tags

  enable_diagnostics             = local.enable_diagnostics
  enable_ipv6                    = local.enable_ipv6
  log_analytics_workspace_name   = module.common.log_analytics_workspaces["region1"].name
  network_watcher_name           = "NetworkWatcher_${local.region1}"
  network_watcher_resource_group = "NetworkWatcherRG"

  vnets_linked_to_ruleset = [
    { name = "hub1", vnet_id = module.hub1.vnet.id },
  ]

  nsg_subnet_map = {
    "ProdSubnet"         = module.common.nsg_main["region1"].id
    "NonProdSubnet"      = module.common.nsg_main["region1"].id
    "NetAppFileSubnet"   = module.common.nsg_main["region1"].id
    "UntrustSubnet"      = module.common.nsg_nva["region1"].id
    "TrustSubnet"        = module.common.nsg_main["region1"].id
    "AppGatewaySubnet"   = module.common.nsg_lb["region1"].id
    "LoadBalancerSubnet" = module.common.nsg_default["region1"].id
  }

  config_vnet      = local.hub1_features.config_vnet
  config_s2s_vpngw = local.hub1_features.config_s2s_vpngw
  config_p2s_vpngw = local.hub1_features.config_p2s_vpngw
  config_ergw      = local.hub1_features.config_ergw
  config_firewall  = local.hub1_features.config_firewall
  config_nva       = local.hub1_features.config_nva

  depends_on = [
    module.common,
  ]
}

resource "time_sleep" "hub1" {
  create_duration = "90s"
  depends_on = [
    module.hub1
  ]
}

####################################################
# workload
####################################################

locals {
  hub1_cgs_vars = {
    ONPREM_LOCAL_RECORDS = local.hub1_local_records
    REDIRECTED_HOSTS     = local.hub1_redirected_hosts
    FORWARD_ZONES        = local.hub1_forward_zones
    TARGETS              = local.vm_script_targets
    ACCESS_CONTROL_PREFIXES = concat(
      local.private_prefixes,
      ["127.0.0.0/8", "35.199.192.0/19", ]
    )
  }
  # proxy_crawler_vars = merge(local.base_crawler_vars, {
  #   VNET_NAME   = module.hub1.vnet.name
  #   SUBNET_NAME = module.hub1.subnets["PublicSubnet"].name
  #   VM_NAME     = "${local.prefix}-${local.hub1_cgs_hostname}"
  # })
  # proxy_crawler_files = {
  #   "${local.init_dir}/crawler/app/crawler.sh"       = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/crawler.sh", local.proxy_crawler_vars) }
  #   "${local.init_dir}/crawler/app/service_tags.py"  = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/service_tags.py", local.proxy_crawler_vars) }
  #   "${local.init_dir}/crawler/app/requirements.txt" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/requirements.txt", local.proxy_crawler_vars) }
  # }
  hub1_cgs_files = merge(
    local.vm_init_files,
    local.vm_startup_init_files,
    # local.proxy_crawler_files,
    {
      "${local.init_dir}/unbound/Dockerfile"         = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/Dockerfile", {}) }
      "${local.init_dir}/unbound/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/docker-compose.yml", {}) }
      "${local.init_dir}/unbound/setup-unbound.sh"   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/setup-unbound.sh", local.hub1_cgs_vars) }
      "/etc/unbound/unbound.conf"                    = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/unbound.conf", local.hub1_cgs_vars) }

      "${local.init_dir}/squid/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/docker-compose.yml", local.hub1_cgs_vars) }
      "${local.init_dir}/squid/setup-squid.sh"     = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/setup-squid.sh", local.hub1_cgs_vars) }
      "/etc/squid/blocked_sites"                   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/blocked_sites", local.hub1_cgs_vars) }
      "/etc/squid/squid.conf"                      = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/squid.conf", local.hub1_cgs_vars) }
    }
  )
  hub1_local_records = [
    { name = lower(local.hub1_cgs1_fdn), record = local.hub1_cgs1_addr },
    { name = lower(local.hub1_cgs2_fdn), record = local.hub1_cgs2_addr },
    { name = lower(local.hub1_prodvm_fdn), record = local.hub1_prodvm_addr },
    { name = lower(local.hub1_prodhavm_fdn), record = local.hub1_prodhavm_addr },
    { name = lower(local.hub1_nonprodvm_fdn), record = local.hub1_nonprodvm_addr },
    { name = lower(local.hub1_nafvm_fdn), record = local.hub1_nafvm_addr },
  ]
  hub1_redirected_hosts = []
  hub1_forward_zones = [
    { zone = ".", targets = [local.azuredns, ] },
  ]
}

module "hub1_cgs_init" {
  source   = "../../modules/cloud-config-gen"
  packages = ["docker.io", "docker-compose", ]
  files = merge(
    local.vm_startup_init_files,
    local.vm_startup_init_files,
    local.hub1_cgs_files,
  )
  run_commands = [
    "sysctl -w net.ipv4.ip_forward=1",
    "sysctl -w net.ipv4.conf.eth0.disable_xfrm=1",
    "sysctl -w net.ipv4.conf.eth0.disable_policy=1",
    "echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf",
    "sysctl -w net.ipv6.conf.all.forwarding=1",
    "echo 'net.ipv6.conf.all.forwarding=1' >> /etc/sysctl.conf",
    "sysctl -p",
    "echo iptables-persistent iptables-persistent/autosave_v4 boolean false | debconf-set-selections",
    "echo iptables-persistent iptables-persistent/autosave_v6 boolean false | debconf-set-selections",
    "apt-get -y install iptables-persistent",
    "iptables -P FORWARD ACCEPT",
    "iptables -P INPUT ACCEPT",
    "iptables -P OUTPUT ACCEPT",
    "iptables -t nat -A POSTROUTING -d 10.0.0.0/8 -j ACCEPT",
    "iptables -t nat -A POSTROUTING -d 172.16.0.0/12 -j ACCEPT",
    "iptables -t nat -A POSTROUTING -d 192.168.0.0/16 -j ACCEPT",
    "iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE",
    ". ${local.init_dir}/init/startup.sh",
    ". ${local.init_dir}/unbound/setup-unbound.sh",
    ". ${local.init_dir}/squid/setup-squid.sh",
    "docker-compose -f ${local.init_dir}/unbound/docker-compose.yml up -d",
    "docker-compose -f ${local.init_dir}/squid/docker-compose.yml up -d",
    "python3 -m venv ${local.init_dir}/crawler",
  ]
}

# pulbic

module "hub1_cgs1" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.hub1_prefix}-${local.hub1_cgs1_hostname}"
  computer_name   = local.hub1_cgs1_hostname
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.hub1_cgs_init.cloud_config)
  tags            = local.hub1_tags

  interfaces = [
    {
      name               = "${local.hub1_prefix}cgs1-nic"
      subnet_id          = module.hub1.subnets["PublicSubnet"].id
      private_ip_address = local.hub1_cgs1_addr
      create_public_ip   = true
    },
  ]
  depends_on = [
    time_sleep.hub1,
  ]
}

module "hub1_cgs2" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.hub1_prefix}-${local.hub1_cgs2_hostname}"
  computer_name   = local.hub1_cgs2_hostname
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.hub1_cgs_init.cloud_config)
  tags            = local.hub1_tags

  interfaces = [
    {
      name               = "${local.hub1_prefix}cgs2-nic"
      subnet_id          = module.hub1.subnets["PublicSubnet"].id
      private_ip_address = local.hub1_cgs2_addr
      create_public_ip   = true
    },
  ]
  depends_on = [
    time_sleep.hub1,
  ]
}

# production

module "hub1_prodvm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.hub1_prefix}-${local.hub1_prodvm_hostname}"
  computer_name   = local.hub1_prodvm_hostname
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.hub1_cgs_init.cloud_config)
  tags            = local.hub1_tags

  interfaces = [
    {
      name               = "${local.hub1_prefix}prodvm-nic"
      subnet_id          = module.hub1.subnets["ProdSubnet"].id
      private_ip_address = local.hub1_prodvm_addr
    },
  ]
  depends_on = [
    time_sleep.hub1,
  ]
}

module "hub1_prodhavm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.hub1_prefix}-${local.hub1_prodhavm_hostname}"
  computer_name   = local.hub1_prodhavm_hostname
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.hub1_cgs_init.cloud_config)
  tags            = local.hub1_tags

  interfaces = [
    {
      name               = "${local.hub1_prefix}prodhavm-nic"
      subnet_id          = module.hub1.subnets["ProdSubnet"].id
      private_ip_address = local.hub1_prodhavm_addr
    },
  ]
  depends_on = [
    time_sleep.hub1,
  ]
}

# non-production

module "hub1_nonprodvm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.hub1_prefix}-${local.hub1_nonprodvm_hostname}"
  computer_name   = local.hub1_nonprodvm_hostname
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.hub1_cgs_init.cloud_config)
  tags            = local.hub1_tags

  interfaces = [
    {
      name               = "${local.hub1_prefix}nonprodvm-nic"
      subnet_id          = module.hub1.subnets["NonProdSubnet"].id
      private_ip_address = local.hub1_nonprodvm_addr
    },
  ]
  depends_on = [
    time_sleep.hub1,
  ]
}

# netapp files

module "hub1_nafvm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.hub1_prefix}-${local.hub1_nafvm_hostname}"
  computer_name   = local.hub1_nafvm_hostname
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.hub1_cgs_init.cloud_config)
  tags            = local.hub1_tags

  interfaces = [
    {
      name               = "${local.hub1_prefix}nafvm-nic"
      subnet_id          = module.hub1.subnets["NetAppFileSubnet"].id
      private_ip_address = local.hub1_nafvm_addr
    },
  ]
  depends_on = [
    time_sleep.hub1,
  ]
}

