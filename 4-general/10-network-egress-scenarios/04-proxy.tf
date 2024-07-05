
####################################################
# Proxy
####################################################

module "hub1_proxy_init" {
  source   = "../../modules/cloud-config-gen"
  packages = ["docker.io", "docker-compose", ]
  files    = local.hub1_proxy_files

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
  ]
}

module "hub1_proxy" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.hub1_proxy_hostname}"
  computer_name   = local.hub1_proxy_hostname
  location        = local.hub1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(module.hub1_proxy_init.cloud_config)
  tags = merge(
    local.hub1_tags,
    local.hub1_crawler_vars,
    {
      VNET_NAME   = module.hub1.vnet.name
      SUBNET_NAME = module.hub1.subnets["PublicSubnet"].name
    }
  )
  ip_forwarding_enabled = true
  interfaces = [
    {
      name               = "${local.hub1_prefix}proxy-nic"
      subnet_id          = module.hub1.subnets["PublicSubnet"].id
      private_ip_address = local.hub1_proxy_addr
      create_public_ip   = true
    },
  ]
}

resource "time_sleep" "hub1_proxy" {
  create_duration = "120s"
  depends_on = [
    module.hub1,
    module.hub1_proxy,
  ]
}

####################################################
# output files
####################################################

locals {
  hub1_proxy_output_files = {
    "output/proxy-init.yaml"  = module.hub1_proxy_init.cloud_config
    "output/proxy-crawler.sh" = templatefile("../../scripts/init/crawler/app/crawler.sh", local.hub1_crawler_vars)
  }
}

resource "local_file" "hub1_proxy_output_files" {
  for_each = local.hub1_proxy_output_files
  filename = each.key
  content  = each.value
}
