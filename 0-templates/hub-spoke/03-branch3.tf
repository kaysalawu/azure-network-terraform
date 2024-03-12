
####################################################
# vnet
####################################################

# base
#----------------------------

module "branch3" {
  source            = "../../modules/base"
  resource_group    = azurerm_resource_group.rg.name
  prefix            = trimsuffix(local.branch3_prefix, "-")
  location          = local.branch3_location
  storage_account   = module.common.storage_accounts["region2"]
  user_assigned_ids = [azurerm_user_assigned_identity.machine.id, ]
  tags              = local.branch3_tags

  enable_diagnostics = local.enable_diagnostics

  nsg_subnet_map = {
    "MainSubnet"      = module.common.nsg_main["region2"].id
    "TrustSubnet"     = module.common.nsg_main["region2"].id
    "UntrustSubnet"   = module.common.nsg_nva["region2"].id
    "DnsServerSubnet" = module.common.nsg_main["region2"].id
  }

  config_vnet = {
    address_space = local.branch3_address_space
    subnets       = local.branch3_subnets
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
  branch3_unbound_startup = templatefile("../../scripts/unbound/unbound.sh", local.branch3_dns_vars)
  branch3_dns_vars = {
    ONPREM_LOCAL_RECORDS = local.onprem_local_records
    REDIRECTED_HOSTS     = local.onprem_redirected_hosts
    FORWARD_ZONES        = local.branch3_forward_zones
    TARGETS              = local.vm_script_targets
    ACCESS_CONTROL_PREFIXES = concat(
      local.private_prefixes,
      ["127.0.0.0/8", "35.199.192.0/19", ]
    )
  }
  branch3_unbound_files = {
    "${local.branch_dns_init_dir}/app/Dockerfile"     = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/app/Dockerfile", {}) }
    "${local.branch_dns_init_dir}/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/docker-compose.yml", {}) }
    "/etc/unbound/unbound.conf"                       = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/app/conf/unbound.conf", local.branch3_dns_vars) }
    "/etc/unbound/unbound.log"                        = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/app/conf/unbound.log", local.branch3_dns_vars) }
  }
  branch3_forward_zones = [
    { zone = "${local.region1_dns_zone}.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "${local.region2_dns_zone}.", targets = [local.hub2_dns_in_addr, ] },
    { zone = "privatelink.blob.core.windows.net.", targets = [local.hub2_dns_in_addr, ] },
    { zone = "privatelink.azurewebsites.net.", targets = [local.hub2_dns_in_addr, ] },
    { zone = "privatelink.database.windows.net.", targets = [local.hub2_dns_in_addr, ] },
    { zone = "privatelink.table.cosmos.azure.com.", targets = [local.hub2_dns_in_addr, ] },
    { zone = "privatelink.queue.core.windows.net.", targets = [local.hub2_dns_in_addr, ] },
    { zone = "privatelink.file.core.windows.net.", targets = [local.hub2_dns_in_addr, ] },
    { zone = ".", targets = [local.azuredns, ] },
  ]
}

module "branch3_unbound_init" {
  source   = "../../modules/cloud-config-gen"
  packages = ["docker.io", "docker-compose", "dnsutils", "net-tools", ]
  files    = local.branch3_unbound_files
  run_commands = [
    "systemctl stop systemd-resolved",
    "systemctl disable systemd-resolved",
    "echo \"nameserver 8.8.8.8\" > /etc/resolv.conf",
    "systemctl restart unbound",
    "systemctl enable unbound",
    "docker-compose -f ${local.branch_dns_init_dir}/docker-compose.yml up -d",
  ]
}

module "branch3_dns" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.branch3_dns_hostname}"
  computer_name   = local.branch3_dns_hostname
  location        = local.branch3_location
  storage_account = module.common.storage_accounts["region2"]
  custom_data     = base64encode(local.branch3_unbound_startup)
  tags            = local.branch3_tags

  interfaces = [
    {
      name               = "${local.branch3_prefix}dns-main"
      subnet_id          = module.branch3.subnets["MainSubnet"].id
      private_ip_address = local.branch3_dns_addr
      create_public_ip   = true
    },
  ]
}

####################################################
# nva
####################################################

locals {
  branch3_nva_route_map_onprem      = "ONPREM"
  branch3_nva_route_map_azure       = "AZURE"
  branch3_nva_route_map_block_azure = "BLOCK_HUB_GW_SUBNET"
  branch3_nva_vars = {
    LOCAL_ASN = local.branch3_nva_asn
    LOOPBACK0 = local.branch3_nva_loopback0
    LOOPBACKS = []

    PREFIX_LISTS = [
      # "ip prefix-list ${local.branch3_nva_route_map_block_azure} deny ${local.hub2_subnets["GatewaySubnet"].address_prefixes[0]}",
      # "ip prefix-list ${local.branch3_nva_route_map_block_azure} permit 0.0.0.0/0 le 32",
    ]

    ROUTE_MAPS = [
      # "route-map ${local.branch3_nva_route_map_onprem} permit 100",
      # "match ip address prefix-list all",
      # "set as-path prepend ${local.branch3_nva_asn} ${local.branch3_nva_asn} ${local.branch3_nva_asn}",

      # "route-map ${local.branch3_nva_route_map_azure} permit 110",
      # "match ip address prefix-list all",
    ]
    STATIC_ROUTES = [
      { prefix = "0.0.0.0", mask = "0.0.0.0", next_hop = local.branch3_untrust_default_gw },
      { prefix = "${module.hub2.s2s_vpngw_bgp_default_ip0}/32", next_hop = "vti0" },
      { prefix = "${module.hub2.s2s_vpngw_bgp_default_ip1}/32", next_hop = "vti1" },
      { prefix = "${local.branch1_nva_loopback0}/32", next_hop = "vti2" },
      { prefix = local.branch1_nva_untrust_addr, next_hop = local.branch3_untrust_default_gw },
      { prefix = local.branch3_subnets["MainSubnet"].address_prefixes[0], next_hop = local.branch3_untrust_default_gw },
    ]
    TUNNELS = [
      {
        name            = "Tunnel0"
        vti_name        = "vti0"
        unique_id       = 100
        vti_local_addr  = cidrhost(local.vti_range0, 1)
        vti_remote_addr = module.hub2.s2s_vpngw_bgp_default_ip0
        local_ip        = local.branch3_nva_untrust_addr
        local_id        = azurerm_public_ip.branch3_nva_pip[0].ip_address
        remote_ip       = module.hub2.s2s_vpngw_public_ip0
        remote_id       = module.hub2.s2s_vpngw_public_ip0
        psk             = local.psk
      },
      {
        name            = "Tunnel1"
        vti_name        = "vti1"
        unique_id       = 200
        vti_local_addr  = cidrhost(local.vti_range1, 1)
        vti_remote_addr = module.hub2.s2s_vpngw_bgp_default_ip1
        local_ip        = local.branch3_nva_untrust_addr
        local_id        = azurerm_public_ip.branch3_nva_pip[0].ip_address
        remote_ip       = module.hub2.s2s_vpngw_public_ip1
        remote_id       = module.hub2.s2s_vpngw_public_ip1
        psk             = local.psk
      },
      {
        name            = "Tunnel2"
        vti_name        = "vti2"
        unique_id       = 300
        vti_local_addr  = cidrhost(local.vti_range2, 2)
        vti_remote_addr = cidrhost(local.vti_range2, 1)
        local_ip        = local.branch3_nva_untrust_addr
        local_id        = azurerm_public_ip.branch3_nva_pip[0].ip_address
        remote_ip       = azurerm_public_ip.branch1_nva_pip.ip_address
        remote_id       = azurerm_public_ip.branch1_nva_pip.ip_address
        psk             = local.psk
      }
    ]
    BGP_SESSIONS = [
      {
        peer_asn        = module.hub2.s2s_vpngw_bgp_asn
        peer_ip         = module.hub2.s2s_vpngw_bgp_default_ip0
        ebgp_multihop   = true
        source_loopback = true
        route_maps      = []
      },
      {
        peer_asn        = module.hub2.s2s_vpngw_bgp_asn
        peer_ip         = module.hub2.s2s_vpngw_bgp_default_ip1
        ebgp_multihop   = true
        source_loopback = true
        route_maps      = []
      },
      {
        peer_asn        = local.branch1_nva_asn
        peer_ip         = local.branch1_nva_loopback0
        ebgp_multihop   = true
        source_loopback = true
        route_maps      = []
      },
    ]
    BGP_ADVERTISED_PREFIXES = [
      local.branch3_subnets["MainSubnet"].address_prefixes[0],
    ]
  }
  branch3_nva_init = templatefile("../../scripts/linux-nva.sh", merge(local.branch3_nva_vars, {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []
    ENABLE_TRAFFIC_GEN        = false

    IPTABLES_RULES           = []
    ROUTE_MAPS               = []
    TUNNELS                  = []
    FRR_CONF                 = templatefile("../../scripts/frr/frr.conf", merge(local.branch3_nva_vars, {}))
    STRONGSWAN_VTI_SCRIPT    = templatefile("../../scripts/strongswan/ipsec-vti.sh", local.branch3_nva_vars)
    STRONGSWAN_IPSEC_SECRETS = templatefile("../../scripts/strongswan/ipsec.secrets", local.branch3_nva_vars)
    STRONGSWAN_IPSEC_CONF    = templatefile("../../scripts/strongswan/ipsec.conf", local.branch3_nva_vars)
  }))
}

module "branch3_nva" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.branch3_nva_hostname}"
  computer_name   = local.branch3_nva_hostname
  location        = local.branch3_location
  storage_account = module.common.storage_accounts["region2"]
  custom_data     = base64encode(local.branch3_nva_init)
  tags            = local.branch3_tags

  source_image_publisher = "Canonical"
  source_image_offer     = "0001-com-ubuntu-server-focal"
  source_image_sku       = "20_04-lts"
  source_image_version   = "latest"

  enable_ip_forwarding = true
  interfaces = [
    {
      name                 = "${local.branch3_prefix}nva-untrust-nic"
      subnet_id            = module.branch3.subnets["UntrustSubnet"].id
      private_ip_address   = local.branch3_nva_untrust_addr
      public_ip_address_id = azurerm_public_ip.branch3_nva_pip[0].id
    },
    {
      name               = "${local.branch3_prefix}nva-trust-nic"
      subnet_id          = module.branch3.subnets["TrustSubnet"].id
      private_ip_address = local.branch3_nva_trust_addr
    },
  ]
  depends_on = [module.branch3]
}

####################################################
# workload
####################################################

locals {
  branch3_vm_init = templatefile("../../scripts/server.sh", {
    USER_ASSIGNED_ID          = azurerm_user_assigned_identity.machine.id
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
    ENABLE_TRAFFIC_GEN        = true
  })
}

module "branch3_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.branch3_vm_hostname}"
  computer_name   = local.branch3_vm_hostname
  location        = local.branch3_location
  storage_account = module.common.storage_accounts["region2"]
  dns_servers     = [local.branch3_dns_addr, ]
  custom_data     = base64encode(local.branch3_vm_init)
  tags            = local.branch3_tags

  interfaces = [
    {
      name               = "${local.branch3_prefix}vm-main-nic"
      subnet_id          = module.branch3.subnets["MainSubnet"].id
      private_ip_address = local.branch3_vm_addr
      create_public_ip   = true
    },
  ]
  depends_on = [
    module.branch3,
    module.branch3_dns,
    module.branch3_nva,
  ]
}

####################################################
# udr
####################################################

# main

locals {
  branch3_routes_main = [
    {
      name                   = "private"
      address_prefix         = local.private_prefixes
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = local.branch3_nva_untrust_addr
    },
  ]
}

module "branch3_udr_main" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.branch3_prefix}main"
  location       = local.branch3_location
  subnet_id      = module.branch3.subnets["MainSubnet"].id
  routes         = local.branch3_routes_main

  disable_bgp_route_propagation = true
  depends_on = [
    module.branch3,
    module.branch3_dns,
    module.branch3_nva,
  ]
}

####################################################
# output files
####################################################

locals {
  branch3_files = {
    "output/branch3Dns.sh" = local.branch3_unbound_startup
    "output/branch3Nva.sh" = local.branch3_nva_init
    "output/branch3Vm.sh"  = local.branch3_vm_init
  }
}

resource "local_file" "branch3_files" {
  for_each = local.branch3_files
  filename = each.key
  content  = each.value
}
