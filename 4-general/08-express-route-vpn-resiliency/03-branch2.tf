
####################################################
# vnet
####################################################

# base
#----------------------------

module "branch2" {
  source          = "../../modules/base"
  resource_group  = azurerm_resource_group.rg.name
  prefix          = trimsuffix(local.branch2_prefix, "-")
  location        = local.branch2_location
  storage_account = module.common.storage_accounts["region1"]
  tags            = local.branch2_tags

  enable_diagnostics           = local.enable_diagnostics
  log_analytics_workspace_name = module.common.log_analytics_workspaces["region1"].name

  nsg_subnet_map = {
    "MainSubnet"      = module.common.nsg_main["region1"].id
    "UntrustSubnet"   = module.common.nsg_nva["region1"].id
    "TrustSubnet"     = module.common.nsg_main["region1"].id
    "DnsServerSubnet" = module.common.nsg_main["region1"].id
    "TestSubnet"      = module.common.nsg_main["region1"].id
  }

  config_vnet = {
    bgp_community = local.branch2_bgp_community
    address_space = local.branch2_address_space
    subnets       = local.branch2_subnets
    nat_gateway_subnet_names = [
      "MainSubnet",
      "TrustSubnet",
      "DnsServerSubnet",
      "TestSubnet",
    ]
    enable_ars = true
  }

  config_ergw = {
    enable = true
    sku    = "ErGw1AZ"
  }

  config_s2s_vpngw = {
    enable = false
    sku    = "VpnGw1AZ"
  }

  depends_on = [
    module.common,
  ]
}

resource "time_sleep" "branch2" {
  create_duration = "90s"
  depends_on = [
    module.branch2
  ]
}

####################################################
# dns
####################################################

locals {
  branch2_unbound_startup = templatefile("../../scripts/unbound/unbound.sh", local.branch2_dns_vars)
  branch2_dns_vars = {
    ONPREM_LOCAL_RECORDS = local.onprem_local_records
    REDIRECTED_HOSTS     = local.onprem_redirected_hosts
    FORWARD_ZONES        = local.branch2_forward_zones
    TARGETS              = local.vm_script_targets
    ACCESS_CONTROL_PREFIXES = concat(
      local.private_prefixes,
      ["127.0.0.0/8", "35.199.192.0/19", ]
    )
  }
  branch2_forward_zones = [
    { zone = "${local.region1_dns_zone}.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.blob.core.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.azurewebsites.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.database.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.table.cosmos.azure.com.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.queue.core.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = "privatelink.file.core.windows.net.", targets = [local.hub1_dns_in_addr, ] },
    { zone = ".", targets = [local.azuredns, ] },
  ]
}

module "branch2_dns" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.branch2_dns_hostname}"
  computer_name   = local.branch2_dns_hostname
  location        = local.branch2_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.branch2_unbound_startup)
  tags            = local.branch2_tags

  interfaces = [
    {
      name               = "${local.branch2_prefix}dns-main"
      subnet_id          = module.branch2.subnets["MainSubnet"].id
      private_ip_address = local.branch2_dns_addr
    },
  ]
  depends_on = [
    time_sleep.branch2,
  ]
}

####################################################
# nva
####################################################

locals {
  branch2_nva_rmap_azure_ipsec_pri_in      = "AZURE_IPSEC_PRIMARY_IN"
  branch2_nva_rmap_azure_ipsec_sec_in      = "AZURE_IPSEC_SECONDARY_IN"
  branch2_nva_rmap_azure_ipsec_pri_out     = "AZURE_IPSEC_PRIMARY_OUT"
  branch2_nva_rmap_azure_ipsec_sec_out     = "AZURE_IPSEC_SECONDARY_OUT"
  branch2_nva_rmap_prefer_express_route_in = "PREFER_EXPRESS_ROUTE_IN"
  branch2_nva_vars = {
    LOCAL_ASN = local.branch2_nva_asn
    LOOPBACK0 = local.branch2_nva_loopback0
    LOOPBACKS = []

    PREFIX_LISTS = [
      "ip prefix-list ALL permit 0.0.0.0/0 le 32",
      "bgp as-path access-list 10 permit ^${local.azure_internal_asn}_${local.azure_asn}_${local.megaport_asn}_${local.azure_asn}$",
    ]
    ROUTE_MAPS = [
      # prefer express route (longer as-path) azure --> onprem
      "route-map ${local.branch2_nva_rmap_prefer_express_route_in} permit 10",
      "match as-path 10",
      "set local-preference 300",

      # ipsec primary: azure --> onprem
      "route-map ${local.branch2_nva_rmap_azure_ipsec_pri_in} permit 10",
      "match ip address prefix-list ALL",
      "set local-preference 200",

      # ipsec secondary: azure --> onprem
      "route-map ${local.branch2_nva_rmap_azure_ipsec_sec_in} permit 10",
      "match ip address prefix-list ALL",
      "set local-preference 100",

      # ipsec primary: onprem --> azure
      "route-map ${local.branch2_nva_rmap_azure_ipsec_pri_out} permit 10",
      "match ip address prefix-list ALL",
      "set as-path prepend ${local.branch2_nva_asn} ${local.branch2_nva_asn} ${local.branch2_nva_asn} ${local.branch2_nva_asn} ${local.branch2_nva_asn}",

      # ipsec secondary: onprem --> azure
      "route-map ${local.branch2_nva_rmap_azure_ipsec_sec_out} permit 10",
      "match ip address prefix-list ALL",
      "set as-path prepend ${local.branch2_nva_asn} ${local.branch2_nva_asn} ${local.branch2_nva_asn} ${local.branch2_nva_asn} ${local.branch2_nva_asn} ${local.branch2_nva_asn}",
    ]
    STATIC_ROUTES = [
      { prefix = "0.0.0.0/0", next_hop = local.branch2_untrust_default_gw },
      { prefix = "${module.branch2.ars_bgp_ip0}/32", next_hop = local.branch2_untrust_default_gw },
      { prefix = "${module.branch2.ars_bgp_ip1}/32", next_hop = local.branch2_untrust_default_gw },
      { prefix = "${module.hub1.s2s_vpngw_bgp_default_ip0}/32", next_hop = "vti0" },
      { prefix = "${module.hub1.s2s_vpngw_bgp_default_ip1}/32", next_hop = "vti1" },
      { prefix = local.branch2_subnets["MainSubnet"].address_prefixes[0], next_hop = local.branch2_untrust_default_gw },
    ]
    TUNNELS = [
      {
        name            = "Tunnel0"
        vti_name        = "vti0"
        unique_id       = 100
        vti_local_addr  = cidrhost(local.vti_range0, 1)
        vti_remote_addr = module.hub1.s2s_vpngw_bgp_default_ip0
        local_ip        = local.branch2_nva_untrust_addr
        local_id        = azurerm_public_ip.branch2_nva_pip.ip_address
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
        local_ip        = local.branch2_nva_untrust_addr
        local_id        = azurerm_public_ip.branch2_nva_pip.ip_address
        remote_ip       = module.hub1.s2s_vpngw_public_ip1
        remote_id       = module.hub1.s2s_vpngw_public_ip1
        psk             = local.psk
      },
    ]
    BGP_SESSIONS_IPV4 = [
      {
        peer_asn        = module.hub1.s2s_vpngw_bgp_asn
        peer_ip         = module.hub1.s2s_vpngw_bgp_default_ip0
        ebgp_multihop   = true
        source_loopback = true
        route_maps = [
          { direction = "in", name = local.branch2_nva_rmap_azure_ipsec_pri_in },
          { direction = "out", name = local.branch2_nva_rmap_azure_ipsec_pri_out },
        ]
      },
      {
        peer_asn        = module.hub1.s2s_vpngw_bgp_asn
        peer_ip         = module.hub1.s2s_vpngw_bgp_default_ip1
        ebgp_multihop   = true
        source_loopback = true
        route_maps = [
          { direction = "in", name = local.branch2_nva_rmap_azure_ipsec_sec_in },
          { direction = "out", name = local.branch2_nva_rmap_azure_ipsec_sec_out },
        ]
      },
      {
        peer_asn        = module.branch2.ars_bgp_asn
        peer_ip         = module.branch2.ars_bgp_ip0
        ebgp_multihop   = true
        source_loopback = false
        as_override     = true
        route_maps = [
          { direction = "in", name = local.branch2_nva_rmap_prefer_express_route_in },
        ]
      },
      {
        peer_asn        = module.branch2.ars_bgp_asn
        peer_ip         = module.branch2.ars_bgp_ip1
        ebgp_multihop   = true
        source_loopback = false
        as_override     = true
        route_maps = [
          { direction = "in", name = local.branch2_nva_rmap_prefer_express_route_in },
        ]
      },
    ]
    BGP_ADVERTISED_PREFIXES_IPV4 = [
      local.branch2_address_space[0],
      local.branch2_address_space[0],
    ]
  }
  branch2_nva_init = templatefile("../../scripts/linux-nva.sh", merge(local.branch2_nva_vars, {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []

    IPTABLES_RULES           = []
    FRR_CONF                 = templatefile("../../scripts/frr/frr.conf", merge(local.branch2_nva_vars, {}))
    STRONGSWAN_VTI_SCRIPT    = templatefile("../../scripts/strongswan/ipsec-vti.sh", local.branch2_nva_vars)
    STRONGSWAN_IPSEC_SECRETS = templatefile("../../scripts/strongswan/ipsec.secrets", local.branch2_nva_vars)
    STRONGSWAN_IPSEC_CONF    = templatefile("../../scripts/strongswan/ipsec.conf", local.branch2_nva_vars)
    STRONGSWAN_AUTO_RESTART  = templatefile("../../scripts/strongswan/ipsec-auto-restart.sh", local.branch2_nva_vars)
  }))
}

module "branch2_nva" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.branch2_nva_hostname}"
  computer_name   = local.branch2_nva_hostname
  location        = local.branch2_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.branch2_nva_init)
  tags            = local.branch2_tags

  source_image_publisher = "Canonical"
  source_image_offer     = "0001-com-ubuntu-server-focal"
  source_image_sku       = "20_04-lts"
  source_image_version   = "latest"

  ip_forwarding_enabled = true
  interfaces = [
    {
      name                 = "${local.branch2_prefix}nva-untrust-nic"
      subnet_id            = module.branch2.subnets["UntrustSubnet"].id
      private_ip_address   = local.branch2_nva_untrust_addr
      public_ip_address_id = azurerm_public_ip.branch2_nva_pip.id
    },
    {
      name               = "${local.branch2_prefix}nva-trust-nic"
      subnet_id          = module.branch2.subnets["TrustSubnet"].id
      private_ip_address = local.branch2_nva_trust_addr
    },
  ]
}

####################################################
# workload
####################################################

module "branch2_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.branch2_vm_hostname}"
  computer_name   = local.branch2_vm_hostname
  location        = local.branch2_location
  storage_account = module.common.storage_accounts["region1"]
  dns_servers     = [local.branch2_dns_addr, ]
  custom_data     = base64encode(module.probe_vm_cloud_init.cloud_config)
  tags            = local.branch2_tags

  interfaces = [
    {
      name               = "${local.branch2_prefix}vm-main-nic"
      subnet_id          = module.branch2.subnets["MainSubnet"].id
      private_ip_address = local.branch2_vm_addr
    },
  ]
  depends_on = [
    module.branch2_dns,
    module.branch2_nva,
    time_sleep.branch2,
  ]
}

####################################################
# udr
####################################################

# main

locals {
  branch2_routes_main = [
    {
      name                   = "private"
      address_prefix         = ["10.0.0.0/8"]
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = local.branch2_nva_untrust_addr
    }
  ]
}

module "branch2_udr_main" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.branch2_prefix}main"
  location       = local.branch2_location
  subnet_id      = module.branch2.subnets["MainSubnet"].id
  routes         = local.branch2_routes_main

  disable_bgp_route_propagation = true
  depends_on = [
    module.branch2_dns,
    module.branch2_nva,
    time_sleep.branch2,
  ]
}

# gateway

locals {
  branch2_routes_gateway = [
    {
      name                   = "main"
      address_prefix         = local.branch2_subnets["MainSubnet"].address_prefixes
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = local.branch2_nva_untrust_addr
    }
  ]
}

module "branch2_udr_gateway" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.branch2_prefix}gateway"
  location       = local.branch2_location
  subnet_id      = module.branch2.subnets["GatewaySubnet"].id
  routes         = local.branch2_routes_gateway

  depends_on = [
    module.branch2_dns,
    module.branch2_nva,
    time_sleep.branch2,
  ]
}

####################################################
# ars
####################################################

# bgp connection

resource "azurerm_route_server_bgp_connection" "branch2_rs_bgp_conn" {
  name            = "${local.branch2_prefix}rs-bgp-conn"
  route_server_id = module.branch2.ars.id
  peer_asn        = local.branch2_nva_asn
  peer_ip         = local.branch2_nva_untrust_addr
}

####################################################
# output files
####################################################

locals {
  branch2_files = {
    "output/branch2Dns.sh" = local.branch2_unbound_startup
    "output/branch2Nva.sh" = local.branch2_nva_init
  }
}

resource "local_file" "branch2_files" {
  for_each = local.branch2_files
  filename = each.key
  content  = each.value
}
