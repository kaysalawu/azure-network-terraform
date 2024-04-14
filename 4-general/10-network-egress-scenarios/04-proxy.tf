
####################################################
# Proxy
####################################################

locals {
  hub_proxy_startup = templatefile("../../scripts/unbound/unbound.sh", local.hub_proxy_vars)
  hub_proxy_vars = {
    ONPREM_LOCAL_RECORDS = local.hub_local_records
    REDIRECTED_HOSTS     = local.hub_redirected_hosts
    FORWARD_ZONES        = local.hub_forward_zones
    TARGETS              = local.vm_script_targets
    ACCESS_CONTROL_PREFIXES = concat(
      local.private_prefixes,
      ["127.0.0.0/8", "35.199.192.0/19", ]
    )
  }
  proxy_crawler_vars = merge(local.hub_crawler_vars, {
    VNET_NAME   = module.hub.vnet.name
    SUBNET_NAME = module.hub.subnets["PublicSubnet"].name
    VM_NAME     = "${local.prefix}-${local.hub_proxy_hostname}"
  })
  proxy_crawler_files = {
    "${local.init_dir}/crawler/app/crawler.sh"       = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/crawler.sh", local.proxy_crawler_vars) }
    "${local.init_dir}/crawler/app/service_tags.py"  = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/service_tags.py", local.proxy_crawler_vars) }
    "${local.init_dir}/crawler/app/requirements.txt" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/crawler/app/requirements.txt", local.proxy_crawler_vars) }
  }
  hub_proxy_files = merge(
    local.proxy_crawler_files,
    local.hub_server_files,
    {
      "${local.init_dir}/unbound/Dockerfile"         = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/Dockerfile", {}) }
      "${local.init_dir}/unbound/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/docker-compose.yml", {}) }
      "${local.init_dir}/unbound/setup-unbound.sh"   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/setup-unbound.sh", local.hub_proxy_vars) }
      "/etc/unbound/unbound.conf"                    = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/unbound.conf", local.hub_proxy_vars) }

      "${local.init_dir}/squid/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/docker-compose.yml", local.hub_proxy_vars) }
      "${local.init_dir}/squid/setup-squid.sh"     = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/setup-squid.sh", local.hub_proxy_vars) }
      "/etc/squid/blocked_sites"                   = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/blocked_sites", local.hub_proxy_vars) }
      "/etc/squid/squid.conf"                      = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/squid.conf", local.hub_proxy_vars) }
    }
  )
  hub_local_records = [
    { name = lower(local.hub_server1_fqdn), record = local.hub_server1_addr },
    { name = lower(local.hub_server2_fqdn), record = local.hub_server2_addr },
    { name = lower(local.hub_proxy_fqdn), record = local.hub_proxy_addr },
  ]
  hub_redirected_hosts = []
  hub_forward_zones = [
    { zone = ".", targets = [local.azuredns, ] },
  ]
}

module "hub_proxy_init" {
  source   = "../../modules/cloud-config-gen"
  packages = ["docker.io", "docker-compose", #npm, "dnsutils", "net-tools", ]
  files    = local.hub_proxy_files
  run_commands = [
    ". ${local.init_dir}/init/server.sh",
    ". ${local.init_dir}/unbound/setup-unbound.sh",
    ". ${local.init_dir}/squid/setup-squid.sh",
    "docker-compose -f ${local.init_dir}/unbound/docker-compose.yml up -d",
    "docker-compose -f ${local.init_dir}/squid/docker-compose.yml up -d",
    "python3 -m venv ${local.init_dir}/crawler",
  ]
}

module "hub_proxy" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.hub_proxy_hostname}"
  computer_name   = local.hub_proxy_hostname
  location        = local.hub_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.hub_proxy_init.cloud_config)
  tags            = local.hub_tags

  interfaces = [
    {
      name               = "${local.hub_prefix}proxy-prod-nic"
      subnet_id          = module.hub.subnets["PublicSubnet"].id
      private_ip_address = local.hub_proxy_addr
      #create_public_ip   = true
    },
  ]
}

####################################################
# output files
####################################################

locals {
  hub_proxy_output_files = {
    "output/proxy-init.yaml"  = module.hub_proxy_init.cloud_config
    "output/proxy-crawler.sh" = templatefile("../../scripts/init/crawler/app/crawler.sh", local.proxy_crawler_vars)
  }
}

resource "local_file" "hub_proxy_output_files" {
  for_each = local.hub_proxy_output_files
  filename = each.key
  content  = each.value
}
