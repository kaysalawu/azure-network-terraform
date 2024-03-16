
####################################################
# customer gateway server (cgs)
####################################################

locals {
  ecs_cgs_init_dir = "/var/lib/labs"
  ecs_cgs_startup  = templatefile("../../scripts/unbound/unbound.sh", local.ecs_cgs_vars)
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
  ecs_cgs_files = {
    "${local.ecs_cgs_init_dir}/unbound/Dockerfile"         = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/Dockerfile", {}) }
    "${local.ecs_cgs_init_dir}/unbound/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/docker-compose.yml", {}) }
    "/etc/unbound/unbound.conf"                            = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/conf/unbound.conf", local.ecs_cgs_vars) }

    "${local.ecs_cgs_init_dir}/squid/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/docker-compose.yml", {}) }
    "/etc/squid/blocked_sites"                           = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/conf/blocked_sites", {}) }
    "/etc/squid/squid.conf"                              = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/squid/conf/squid.conf", local.ecs_cgs_vars) }
  }
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
    "systemctl stop systemd-resolved",
    "systemctl disable systemd-resolved",
    "echo \"nameserver 8.8.8.8\" > /etc/resolv.conf",
    "touch /etc/unbound/unbound.log",
    "docker-compose -f ${local.ecs_cgs_init_dir}/unbound/docker-compose.yml up -d",
    "docker-compose -f ${local.ecs_cgs_init_dir}/squid/docker-compose.yml up -d",
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
      create_public_ip   = true
    },
  ]
}

####################################################
# output files
####################################################

locals {
  ecs_files = {
    "output/ecs-cgs-init.yaml" = module.ecs_cgs_init.cloud_config
  }
}

resource "local_file" "ecs_files" {
  for_each = local.ecs_files
  filename = each.key
  content  = each.value
}
