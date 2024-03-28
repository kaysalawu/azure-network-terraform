
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
  storage_account = module.common.storage_accounts["region2"]
  tags            = local.branch2_tags

  enable_diagnostics = local.enable_diagnostics

  nsg_subnet_map = {
    "MainSubnet"      = module.common.nsg_main["region2"].id
    "TrustSubnet"     = module.common.nsg_main["region2"].id
    "UntrustSubnet"   = module.common.nsg_nva["region2"].id
    "DnsServerSubnet" = module.common.nsg_main["region2"].id
  }

  config_vnet = {
    address_space = local.branch2_address_space
    subnets       = local.branch2_subnets
  }

  config_ergw = {
    enable = true
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
    { zone = "${local.region1_dns_zone}.", targets = [local.hub2_dns_in_addr, ] },
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

module "branch2_dns" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.branch2_dns_hostname}"
  computer_name   = local.branch2_dns_hostname
  location        = local.branch2_location
  storage_account = module.common.storage_accounts["region2"]
  custom_data     = base64encode(local.branch2_unbound_startup)
  tags            = local.branch2_tags

  interfaces = [
    {
      name               = "${local.branch2_prefix}dns-main"
      subnet_id          = module.branch2.subnets["MainSubnet"].id
      private_ip_address = local.branch2_dns_addr
      create_public_ip   = true
    },
  ]
}

####################################################
# nva
####################################################

locals {
  branch2_nva_route_map_onprem      = "ONPREM"
  branch2_nva_route_map_azure       = "AZURE"
  branch2_nva_route_map_block_azure = "BLOCK_HUB_GW_SUBNET"
  branch2_nva_vars = {
    LOCAL_ASN = local.branch2_nva_asn
    LOOPBACK0 = local.branch2_nva_loopback0
    LOOPBACKS = []

    PREFIX_LISTS = []

    ROUTE_MAPS = [
      # do nothing (placeholder for future use)
      "route-map ${local.branch2_nva_route_map_azure} permit 110",
      "match ip address prefix-list all",
    ]
    STATIC_ROUTES = [
      { prefix = "0.0.0.0/0", next_hop = local.branch2_untrust_default_gw },
      { prefix = "${module.vhub1.vpngw_bgp_ip0}/32", next_hop = "vti0" },
      { prefix = "${module.vhub1.vpngw_bgp_ip1}/32", next_hop = "vti1" },
      { prefix = "${local.branch3_nva_loopback0}/32", next_hop = "vti2" },
      { prefix = local.branch3_nva_untrust_addr, next_hop = local.branch2_untrust_default_gw },
      { prefix = local.branch2_subnets["MainSubnet"].address_prefixes[0], next_hop = local.branch2_untrust_default_gw },
    ]
    TUNNELS = [
      {
        name            = "Tunnel0"
        vti_name        = "vti0"
        unique_id       = 100
        vti_local_addr  = cidrhost(local.vti_range0, 1)
        vti_remote_addr = module.vhub1.vpngw_bgp_ip0
        local_ip        = local.branch2_nva_untrust_addr
        local_id        = azurerm_public_ip.branch2_nva_pip.ip_address
        remote_ip       = module.vhub1.vpngw_public_ip0
        remote_id       = module.vhub1.vpngw_public_ip0
        psk             = local.psk
      },
      {
        name            = "Tunnel1"
        vti_name        = "vti1"
        unique_id       = 200
        vti_local_addr  = cidrhost(local.vti_range1, 1)
        vti_remote_addr = module.vhub1.vpngw_bgp_ip1
        local_ip        = local.branch2_nva_untrust_addr
        local_id        = azurerm_public_ip.branch2_nva_pip.ip_address
        remote_ip       = module.vhub1.vpngw_public_ip1
        remote_id       = module.vhub1.vpngw_public_ip1
        psk             = local.psk
      },
    ]
    BGP_SESSIONS = [
      {
        peer_asn        = module.vhub1.bgp_asn
        peer_ip         = module.vhub1.vpngw_bgp_ip0
        ebgp_multihop   = true
        source_loopback = true
        route_maps      = []
      },
      {
        peer_asn        = module.vhub1.bgp_asn
        peer_ip         = module.vhub1.vpngw_bgp_ip1
        ebgp_multihop   = true
        source_loopback = true
        route_maps      = []
      },
    ]
    BGP_ADVERTISED_PREFIXES = [
      local.branch2_subnets["MainSubnet"].address_prefixes[0],
    ]
  }
  branch2_nva_init = templatefile("../../scripts/linux-nva.sh", merge(local.branch2_nva_vars, {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = []
    TARGETS_HEAVY_TRAFFIC_GEN = []

    IPTABLES_RULES           = []
    ROUTE_MAPS               = []
    TUNNELS                  = []
    FRR_CONF                 = templatefile("../../scripts/frr/frr.conf", merge(local.branch2_nva_vars, {}))
    STRONGSWAN_VTI_SCRIPT    = templatefile("../../scripts/strongswan/ipsec-vti.sh", local.branch2_nva_vars)
    STRONGSWAN_IPSEC_SECRETS = templatefile("../../scripts/strongswan/ipsec.secrets", local.branch2_nva_vars)
    STRONGSWAN_IPSEC_CONF    = templatefile("../../scripts/strongswan/ipsec.conf", local.branch2_nva_vars)
  }))
}

module "branch2_nva" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.branch2_nva_hostname}"
  computer_name   = local.branch2_nva_hostname
  location        = local.branch2_location
  storage_account = module.common.storage_accounts["region2"]
  custom_data     = base64encode(local.branch2_nva_init)
  tags            = local.branch2_tags

  source_image_publisher = "Canonical"
  source_image_offer     = "0001-com-ubuntu-server-focal"
  source_image_sku       = "20_04-lts"
  source_image_version   = "latest"

  enable_ip_forwarding = true
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
  depends_on = [module.branch2]
}

####################################################
# workload
####################################################

locals {
  branch2_vm_init = templatefile("../../scripts/server.sh", {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
  })
}

module "branch2_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.prefix}-${local.branch2_vm_hostname}"
  computer_name   = local.branch2_vm_hostname
  location        = local.branch2_location
  storage_account = module.common.storage_accounts["region2"]
  dns_servers     = [local.branch2_dns_addr, ]
  custom_data     = base64encode(local.branch2_vm_init)
  tags            = local.branch2_tags

  interfaces = [
    {
      name               = "${local.branch2_prefix}vm-main-nic"
      subnet_id          = module.branch2.subnets["MainSubnet"].id
      private_ip_address = local.branch2_vm_addr
      create_public_ip   = true
    },
  ]
  depends_on = [
    module.branch2,
    module.branch2_dns,
  ]
}

####################################################
# udr
####################################################

# main

locals {
  branch2_routes_main = [
  ]
}

module "branch2_udr_main" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.branch2_prefix}main"
  location       = local.branch2_location
  subnet_id      = module.branch2.subnets["MainSubnet"].id
  routes         = local.branch2_routes_main

  disable_bgp_route_propagation = false
  depends_on = [
    module.branch2,
    module.branch2_dns,
  ]
}

####################################################
# output files
####################################################

locals {
  branch2_files = {
    "output/branch2Dns.sh" = local.branch2_unbound_startup
    "output/branch2Vm.sh"  = local.branch2_vm_init
  }
}

resource "local_file" "branch2_files" {
  for_each = local.branch2_files
  filename = each.key
  content  = each.value
}
