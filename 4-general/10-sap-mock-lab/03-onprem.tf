
####################################################
# vnet
####################################################

# base
#----------------------------

module "onprem" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.onprem_prefix, "-")
  location        = local.onprem_location
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.onprem_tags

  enable_diagnostics = local.enable_diagnostics

  nsg_subnet_map = {
    "MainSubnet"      = module.common.nsg_main["region1"].id
    "TrustSubnet"     = module.common.nsg_main["region1"].id
    "UntrustSubnet"   = module.common.nsg_nva["region1"].id
    "DnsServerSubnet" = module.common.nsg_main["region1"].id
  }

  config_vnet = {
    address_space = local.onprem_address_space
    subnets       = local.onprem_subnets
  }

  config_ergw = {
    enable = false
    sku    = "ErGw1AZ"
  }

  depends_on = [
    module.common,
  ]
}

####################################################
# dns
####################################################

locals {
  onprem_unbound_startup = templatefile("../../scripts/unbound/unbound.sh", local.onprem_dns_vars)
  onprem_dns_vars = {
    ONPREM_LOCAL_RECORDS = local.onprem_local_records
    REDIRECTED_HOSTS     = local.onprem_redirected_hosts
    FORWARD_ZONES        = local.onprem_forward_zones
    TARGETS              = local.vm_script_targets
    ACCESS_CONTROL_PREFIXES = concat(
      local.private_prefixes,
      ["127.0.0.0/8", "35.199.192.0/19", ]
    )
  }
  onprem_unbound_files = {
    "${local.branch_dns_init_dir}/unbound/Dockerfile"         = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/Dockerfile", {}) }
    "${local.branch_dns_init_dir}/unbound/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/docker-compose.yml", {}) }
    "/etc/unbound/unbound.conf"                               = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/unbound.conf", local.onprem_dns_vars) }
  }
  onprem_forward_zones = [
    # { zone = "${local.region1_dns_zone}.", targets = [local.ecs_dns_in_addr, ] },
    # { zone = "privatelink.blob.core.windows.net.", targets = [local.ecs_dns_in_addr, ] },
    # { zone = "privatelink.azurewebsites.net.", targets = [local.ecs_dns_in_addr, ] },
    # { zone = "privatelink.database.windows.net.", targets = [local.ecs_dns_in_addr, ] },
    # { zone = "privatelink.table.cosmos.azure.com.", targets = [local.ecs_dns_in_addr, ] },
    # { zone = "privatelink.queue.core.windows.net.", targets = [local.ecs_dns_in_addr, ] },
    # { zone = "privatelink.file.core.windows.net.", targets = [local.ecs_dns_in_addr, ] },
    { zone = ".", targets = [local.azuredns, ] },
  ]
}

module "onprem_unbound_init" {
  source   = "../../modules/cloud-config-gen"
  packages = ["docker.io", "docker-compose", "dnsutils", "net-tools", ]
  files    = local.onprem_unbound_files
  run_commands = [
    "systemctl stop systemd-resolved",
    "systemctl disable systemd-resolved",
    "echo \"nameserver 8.8.8.8\" > /etc/resolv.conf",
    "touch /etc/unbound/unbound.log",
    "systemctl restart unbound",
    "systemctl enable unbound",
    "docker-compose -f ${local.branch_dns_init_dir}/unbound/docker-compose.yml up -d",
  ]
}

module "onprem_dns" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.onprem_dns_hostname}"
  computer_name   = local.onprem_dns_hostname
  location        = local.onprem_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.onprem_unbound_startup)
  tags            = local.onprem_tags

  interfaces = [
    {
      name               = "${local.onprem_prefix}dns-main"
      subnet_id          = module.onprem.subnets["MainSubnet"].id
      private_ip_address = local.onprem_dns_addr
      create_public_ip   = true
    },
  ]
}

####################################################
# nva
####################################################

locals {
  onprem_nva_route_map_onprem      = "ONPREM"
  onprem_nva_route_map_azure       = "AZURE"
  onprem_nva_route_map_block_azure = "BLOCK_HUB_GW_SUBNET"
  onprem_nva_vars = {
    LOCAL_ASN = local.onprem_nva_asn
    LOOPBACK0 = local.onprem_nva_loopback0
    LOOPBACKS = []

    PREFIX_LISTS = [
      # "ip prefix-list ${local.onprem_nva_route_map_block_azure} deny ${local.ecs_subnets["GatewaySubnet"].address_prefixes[0]}",
      # "ip prefix-list ${local.onprem_nva_route_map_block_azure} permit 0.0.0.0/0 le 32",
    ]

    ROUTE_MAPS = [
      # "route-map ${local.onprem_nva_route_map_onprem} permit 100",
      # "match ip address prefix-list all",
      # "set as-path prepend ${local.onprem_nva_asn} ${local.onprem_nva_asn} ${local.onprem_nva_asn}",

      # "route-map ${local.onprem_nva_route_map_azure} permit 110",
      # "match ip address prefix-list all",
    ]
    STATIC_ROUTES = [
      { prefix = "0.0.0.0", mask = "0.0.0.0", next_hop = local.onprem_untrust_default_gw },
      { prefix = "${module.ecs.s2s_vpngw_bgp_default_ip0}/32", next_hop = "vti0" },
      { prefix = "${module.ecs.s2s_vpngw_bgp_default_ip1}/32", next_hop = "vti1" },
      { prefix = local.onprem_subnets["MainSubnet"].address_prefixes[0], next_hop = local.onprem_untrust_default_gw },
    ]
    TUNNELS = [
      {
        name            = "Tunnel0"
        vti_name        = "vti0"
        unique_id       = 100
        vti_local_addr  = cidrhost(local.vti_range0, 1)
        vti_remote_addr = module.ecs.s2s_vpngw_bgp_default_ip0
        local_ip        = local.onprem_nva_untrust_addr
        local_id        = azurerm_public_ip.onprem_nva_pip.ip_address
        remote_ip       = module.ecs.s2s_vpngw_public_ip0
        remote_id       = module.ecs.s2s_vpngw_public_ip0
        psk             = local.psk
      },
      {
        name            = "Tunnel1"
        vti_name        = "vti1"
        unique_id       = 200
        vti_local_addr  = cidrhost(local.vti_range1, 1)
        vti_remote_addr = module.ecs.s2s_vpngw_bgp_default_ip1
        local_ip        = local.onprem_nva_untrust_addr
        local_id        = azurerm_public_ip.onprem_nva_pip.ip_address
        remote_ip       = module.ecs.s2s_vpngw_public_ip1
        remote_id       = module.ecs.s2s_vpngw_public_ip1
        psk             = local.psk
      }
    ]
    BGP_SESSIONS = [
      {
        peer_asn        = module.ecs.s2s_vpngw_bgp_asn
        peer_ip         = module.ecs.s2s_vpngw_bgp_default_ip0
        ebgp_multihop   = true
        source_loopback = true
        route_maps      = []
      },
      {
        peer_asn        = module.ecs.s2s_vpngw_bgp_asn
        peer_ip         = module.ecs.s2s_vpngw_bgp_default_ip1
        ebgp_multihop   = true
        source_loopback = true
        route_maps      = []
      }
    ]
    BGP_ADVERTISED_PREFIXES = [
      local.onprem_subnets["MainSubnet"].address_prefixes[0],
    ]
  }
  onprem_nva_init = templatefile("../../scripts/linux-nva.sh", merge(local.onprem_nva_vars, {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []

    IPTABLES_RULES           = []
    ROUTE_MAPS               = []
    TUNNELS                  = []
    FRR_CONF                 = templatefile("../../scripts/frr/frr.conf", merge(local.onprem_nva_vars, {}))
    STRONGSWAN_VTI_SCRIPT    = templatefile("../../scripts/strongswan/ipsec-vti.sh", local.onprem_nva_vars)
    STRONGSWAN_IPSEC_SECRETS = templatefile("../../scripts/strongswan/ipsec.secrets", local.onprem_nva_vars)
    STRONGSWAN_IPSEC_CONF    = templatefile("../../scripts/strongswan/ipsec.conf", local.onprem_nva_vars)
  }))
}

module "onprem_nva" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.onprem_nva_hostname}"
  computer_name   = local.onprem_nva_hostname
  location        = local.onprem_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.onprem_nva_init)
  tags            = local.onprem_tags

  source_image_publisher = "Canonical"
  source_image_offer     = "0001-com-ubuntu-server-focal"
  source_image_sku       = "20_04-lts"
  source_image_version   = "latest"

  enable_ip_forwarding = true
  interfaces = [
    {
      name                 = "${local.onprem_prefix}nva-untrust-nic"
      subnet_id            = module.onprem.subnets["UntrustSubnet"].id
      private_ip_address   = local.onprem_nva_untrust_addr
      public_ip_address_id = azurerm_public_ip.onprem_nva_pip.id
    },
    {
      name               = "${local.onprem_prefix}nva-trust-nic"
      subnet_id          = module.onprem.subnets["TrustSubnet"].id
      private_ip_address = local.onprem_nva_trust_addr
    },
  ]
  depends_on = [module.onprem]
}

####################################################
# workload
####################################################

locals {
  onprem_vm_init = templatefile("../../scripts/server.sh", {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
  })
}

module "onprem_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.onprem_vm_hostname}"
  computer_name   = local.onprem_vm_hostname
  location        = local.onprem_location
  storage_account = module.common.storage_accounts["region1"]
  dns_servers     = [local.onprem_dns_addr, ]
  custom_data     = base64encode(local.onprem_vm_init)
  tags            = local.onprem_tags

  interfaces = [
    {
      name               = "${local.onprem_prefix}vm-main-nic"
      subnet_id          = module.onprem.subnets["MainSubnet"].id
      private_ip_address = local.onprem_vm_addr
      create_public_ip   = true
    },
  ]
  depends_on = [
    module.onprem,
    module.onprem_dns,
    module.onprem_nva,
  ]
}

####################################################
# udr
####################################################

# main

locals {
  onprem_routes_main = [
    {
      name                   = "private"
      address_prefix         = local.private_prefixes
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = local.onprem_nva_untrust_addr
    },
  ]
}

module "onprem_udr_main" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.onprem_prefix}main"
  location       = local.onprem_location
  subnet_id      = module.onprem.subnets["MainSubnet"].id
  routes         = local.onprem_routes_main

  disable_bgp_route_propagation = true
  depends_on = [
    module.onprem,
    module.onprem_dns,
    module.onprem_nva,
  ]
}

####################################################
# output files
####################################################

locals {
  onprem_files = {
    "output/onpremDns.sh" = local.onprem_unbound_startup
    "output/onpremNva.sh" = local.onprem_nva_init
    "output/onpremVm.sh"  = local.onprem_vm_init
  }
}

resource "local_file" "onprem_files" {
  for_each = local.onprem_files
  filename = each.key
  content  = each.value
}
