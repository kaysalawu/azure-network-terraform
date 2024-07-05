
####################################################
# vnet
####################################################

# base
#----------------------------

module "branch1" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.branch1_prefix, "-")
  location        = local.branch1_location
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.branch1_tags

  enable_diagnostics = local.enable_diagnostics
  enable_ipv6        = local.enable_ipv6

  nsg_subnet_map = {
    "MainSubnet"      = module.common.nsg_main["region1"].id
    "UntrustSubnet"   = module.common.nsg_nva["region1"].id
    "TrustSubnet"     = module.common.nsg_main["region1"].id
    "DnsServerSubnet" = module.common.nsg_main["region1"].id
    "TestSubnet"      = module.common.nsg_main["region1"].id
  }

  config_vnet = {
    address_space = local.branch1_address_space
    subnets       = local.branch1_subnets
    nat_gateway_subnet_names = [
      "MainSubnet",
      "TrustSubnet",
      "DnsServerSubnet",
      "TestSubnet",
    ]
  }

  config_ergw = {
    enable = true
    sku    = "Standard"
  }

  depends_on = [
    module.common,
  ]
}

resource "time_sleep" "branch1" {
  create_duration = "90s"
  depends_on = [
    module.branch1
  ]
}

####################################################
# dns
####################################################

locals {
  branch1_unbound_startup = templatefile("../../scripts/unbound/unbound.sh", local.branch1_dns_vars)
  branch1_dns_vars = {
    ONPREM_LOCAL_RECORDS = local.onprem_local_records
    REDIRECTED_HOSTS     = local.onprem_redirected_hosts
    FORWARD_ZONES        = local.branch1_forward_zones
    TARGETS              = local.vm_script_targets
    ACCESS_CONTROL_PREFIXES = concat(
      local.private_prefixes,
      ["127.0.0.0/8", "35.199.192.0/19", "fd00::/8", ]
    )
  }
  branch1_forward_zones = [
    { zone = "${local.region1_dns_zone}.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "${local.region2_dns_zone}.", targets = [local.hub2_dns_in_addr, ] },
    { zone = "privatelink.blob.core.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.azurewebsites.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.database.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.table.cosmos.azure.com.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.queue.core.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.file.core.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = ".", targets = [local.azuredns, ] },
  ]
}

module "branch1_dns" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.branch1_dns_hostname}"
  computer_name   = local.branch1_dns_hostname
  location        = local.branch1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.branch1_unbound_startup)
  tags            = local.branch1_tags

  enable_ipv6 = local.enable_ipv6
  interfaces = [
    {
      name                 = "${local.branch1_prefix}dns-main"
      subnet_id            = module.branch1.subnets["MainSubnet"].id
      private_ip_address   = local.branch1_dns_addr
      private_ipv6_address = local.branch1_dns_addr_v6
    },
  ]
  depends_on = [
    time_sleep.branch1,
  ]
}

####################################################
# nva
####################################################

locals {
  branch1_nva_route_map_onprem      = "ONPREM"
  branch1_nva_route_map_azure       = "AZURE"
  branch1_nva_route_map_block_azure = "BLOCK_HUB_GW_SUBNET"
  branch1_nva_vars = {
    LOCAL_ASN = local.branch1_nva_asn
    LOOPBACK0 = local.branch1_nva_loopback0
    LOOPBACKS = []

    PREFIX_LISTS = [
      "ip prefix-list ${local.branch1_nva_route_map_block_azure} deny ${local.hub1_address_space[1]}",
      "ip prefix-list ${local.branch1_nva_route_map_block_azure} permit 0.0.0.0/0 le 32",
    ]
    ROUTE_MAPS = [
      # prepend as-path between branches
      "route-map ${local.branch1_nva_route_map_onprem} permit 100",
      "match ip address prefix-list all",
      "set as-path prepend ${local.branch1_nva_asn} ${local.branch1_nva_asn} ${local.branch1_nva_asn}",

      # do nothing (placeholder for future use)
      "route-map ${local.branch1_nva_route_map_azure} permit 110",
      "match ip address prefix-list all",

      # block inbound gateway subnet, allow all other hub and spoke cidrs
      # "route-map ${local.branch1_nva_route_map_block_azure} permit 120",
      # "match ip address prefix-list BLOCK_HUB_GW_SUBNET",
    ]
    STATIC_ROUTES = [
      { prefix = "0.0.0.0/0", next_hop = local.branch1_untrust_default_gw },
      { prefix = "${module.hub1.s2s_vpngw_bgp_default_ip0}/32", next_hop = "vti0" },
      { prefix = "${module.hub1.s2s_vpngw_bgp_default_ip1}/32", next_hop = "vti1" },
      { prefix = "${local.branch3_nva_loopback0}/32", next_hop = "vti2" },
      { prefix = local.branch3_nva_untrust_addr, next_hop = local.branch1_untrust_default_gw },
      { prefix = local.branch1_subnets["MainSubnet"].address_prefixes[0], next_hop = local.branch1_untrust_default_gw },
    ]
    TUNNELS = [
      {
        name            = "Tunnel0"
        vti_name        = "vti0"
        unique_id       = 100
        vti_local_addr  = cidrhost(local.vti_range0, 1)
        vti_remote_addr = module.hub1.s2s_vpngw_bgp_default_ip0
        local_ip        = local.branch1_nva_untrust_addr
        local_id        = azurerm_public_ip.branch1_nva_pip.ip_address
        remote_ip       = module.hub1.s2s_vpngw_public_ip0
        remote_id       = module.hub1.s2s_vpngw_public_ip0
        psk             = local.psk
      },
      {
        name            = "Tunnel1"
        vti_name        = "vti1"
        unique_id       = 200
        vti_local_addr  = cidrhost(local.vti_range1, 1)
        vti_remote_addr = module.hub1.s2s_vpngw_bgp_default_ip1
        local_ip        = local.branch1_nva_untrust_addr
        local_id        = azurerm_public_ip.branch1_nva_pip.ip_address
        remote_ip       = module.hub1.s2s_vpngw_public_ip1
        remote_id       = module.hub1.s2s_vpngw_public_ip1
        psk             = local.psk
      },
      {
        name            = "Tunnel2"
        vti_name        = "vti2"
        unique_id       = 300
        vti_local_addr  = cidrhost(local.vti_range2, 1)
        vti_remote_addr = cidrhost(local.vti_range2, 2)
        local_ip        = local.branch1_nva_untrust_addr
        local_id        = azurerm_public_ip.branch1_nva_pip.ip_address
        remote_ip       = local.enable_onprem_wan_link ? try(azurerm_public_ip.branch3_nva_pip[0].ip_address, "1.1.1.1") : "1.1.1.1"
        remote_id       = local.enable_onprem_wan_link ? try(azurerm_public_ip.branch3_nva_pip[0].ip_address, "1.1.1.1") : "1.1.1.1"
        psk             = local.psk
      }
    ]
    BGP_SESSIONS_IPV4 = [
      {
        peer_asn        = module.hub1.s2s_vpngw_bgp_asn
        peer_ip         = module.hub1.s2s_vpngw_bgp_default_ip0
        ebgp_multihop   = true
        source_loopback = true
        route_maps      = []
      },
      {
        peer_asn        = module.hub1.s2s_vpngw_bgp_asn
        peer_ip         = module.hub1.s2s_vpngw_bgp_default_ip1
        ebgp_multihop   = true
        source_loopback = true
        route_maps      = []
      },
      {
        peer_asn        = local.branch3_nva_asn
        peer_ip         = local.branch3_nva_loopback0
        ebgp_multihop   = true
        source_loopback = true
        route_maps      = []
      },
    ]
    BGP_ADVERTISED_PREFIXES_IPV4 = [
      local.branch1_subnets["MainSubnet"].address_prefixes[0],
    ]
  }
  branch1_nva_init = templatefile("../../scripts/linux-nva.sh", merge(local.branch1_nva_vars, {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []

    IPTABLES_RULES           = []
    FRR_CONF                 = templatefile("../../scripts/frr/frr.conf", merge(local.branch1_nva_vars, {}))
    STRONGSWAN_VTI_SCRIPT    = templatefile("../../scripts/strongswan/ipsec-vti.sh", local.branch1_nva_vars)
    STRONGSWAN_IPSEC_SECRETS = templatefile("../../scripts/strongswan/ipsec.secrets", local.branch1_nva_vars)
    STRONGSWAN_IPSEC_CONF    = templatefile("../../scripts/strongswan/ipsec.conf", local.branch1_nva_vars)
    STRONGSWAN_AUTO_RESTART  = templatefile("../../scripts/strongswan/ipsec-auto-restart.sh", local.branch1_nva_vars)
  }))
}

module "branch1_nva" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.branch1_nva_hostname}"
  computer_name   = local.branch1_nva_hostname
  location        = local.branch1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.branch1_nva_init)
  tags            = local.branch1_tags

  source_image_publisher = "Canonical"
  source_image_offer     = "0001-com-ubuntu-server-focal"
  source_image_sku       = "20_04-lts"
  source_image_version   = "latest"

  ip_forwarding_enabled = true
  enable_ipv6           = local.enable_ipv6
  interfaces = [
    {
      name                 = "${local.branch1_prefix}nva-untrust-nic"
      subnet_id            = module.branch1.subnets["UntrustSubnet"].id
      private_ip_address   = local.branch1_nva_untrust_addr
      private_ipv6_address = local.branch1_nva_untrust_addr_v6
      public_ip_address_id = azurerm_public_ip.branch1_nva_pip.id
    },
    {
      name                 = "${local.branch1_prefix}nva-trust-nic"
      subnet_id            = module.branch1.subnets["TrustSubnet"].id
      private_ip_address   = local.branch1_nva_trust_addr
      private_ipv6_address = local.branch1_nva_trust_addr_v6
    },
  ]
}

####################################################
# workload
####################################################

module "branch1_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.branch1_vm_hostname}"
  computer_name   = local.branch1_vm_hostname
  location        = local.branch1_location
  storage_account = module.common.storage_accounts["region1"]
  dns_servers     = [local.branch1_dns_addr, ]
  custom_data     = base64encode(module.probe_vm_cloud_init.cloud_config)
  tags            = local.branch1_tags

  enable_ipv6 = local.enable_ipv6
  interfaces = [
    {
      name                 = "${local.branch1_prefix}vm-main-nic"
      subnet_id            = module.branch1.subnets["MainSubnet"].id
      private_ip_address   = local.branch1_vm_addr
      private_ipv6_address = local.branch1_vm_addr_v6
    },
  ]
  depends_on = [
    module.branch1_dns,
    module.branch1_nva,
    time_sleep.branch1,
  ]
}

####################################################
# udr
####################################################

# main

locals {
  branch1_routes_main = [
    {
      name                   = "private"
      address_prefix         = local.private_prefixes
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = local.branch1_nva_untrust_addr
    },
  ]
}

module "branch1_udr_main" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.branch1_prefix}main"
  location       = local.branch1_location
  subnet_id      = module.branch1.subnets["MainSubnet"].id
  routes         = local.branch1_routes_main

  disable_bgp_route_propagation = true
  depends_on = [
    module.branch1_dns,
    module.branch1_nva,
    time_sleep.branch1,
  ]
}

####################################################
# output files
####################################################

locals {
  branch1_files = {
    "output/branch1Dns.sh" = local.branch1_unbound_startup
    "output/branch1Nva.sh" = local.branch1_nva_init
  }
}

resource "local_file" "branch1_files" {
  for_each = local.branch1_files
  filename = each.key
  content  = each.value
}
