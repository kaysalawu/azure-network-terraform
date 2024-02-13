
####################################################
# vnet
####################################################

# base
#----------------------------

module "branch1" {
  source             = "../../modules/base"
  resource_group     = azurerm_resource_group.rg.name
  prefix             = trimsuffix(local.branch1_prefix, "-")
  location           = local.branch1_location
  storage_account    = module.common.storage_accounts["region1"]
  enable_diagnostics = local.enable_diagnostics
  tags               = local.branch1_tags

  nsg_subnet_map = {
    "MainSubnet"      = module.common.nsg_main["region1"].id
    "TrustSubnet"     = module.common.nsg_main["region1"].id
    "UntrustSubnet"   = module.common.nsg_nva["region1"].id
    "DnsServerSubnet" = module.common.nsg_main["region1"].id
  }

  config_vnet = {
    address_space = local.branch1_address_space
    subnets       = local.branch1_subnets
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
  branch1_unbound_startup = templatefile("../../scripts/unbound/unbound.sh", local.branch1_dns_vars)
  branch1_dns_vars = {
    ONPREM_LOCAL_RECORDS = local.onprem_local_records
    REDIRECTED_HOSTS     = local.onprem_redirected_hosts
    FORWARD_ZONES        = local.branch1_forward_zones
    TARGETS              = local.vm_script_targets
    ACCESS_CONTROL_PREFIXES = concat(
      local.private_prefixes,
      ["127.0.0.0/8", "35.199.192.0/19", ]
    )
  }
  branch1_unbound_files = {
    "${local.branch_dns_init_dir}/app/Dockerfile"     = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/app/Dockerfile", {}) }
    "${local.branch_dns_init_dir}/docker-compose.yml" = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/docker-compose.yml", {}) }
    "/etc/unbound/unbound.conf"                       = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/app/conf/unbound.conf", local.branch1_dns_vars) }
    "/etc/unbound/unbound.log"                        = { owner = "root", permissions = "0744", content = templatefile("../../scripts/init/unbound/app/conf/unbound.log", local.branch1_dns_vars) }
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

module "branch1_unbound_init" {
  source   = "../../modules/cloud-config-gen"
  packages = ["docker.io", "docker-compose", "dnsutils", "net-tools", ]
  files    = local.branch1_unbound_files
  run_commands = [
    "systemctl stop systemd-resolved",
    "systemctl disable systemd-resolved",
    "echo \"nameserver 8.8.8.8\" > /etc/resolv.conf",
    "systemctl restart unbound",
    "systemctl enable unbound",
    "docker-compose -f ${local.branch_dns_init_dir}/docker-compose.yml up -d",
  ]
}

module "branch1_dns" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.branch1_prefix}dns"
  location        = local.branch1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.branch1_unbound_startup)
  identity_ids    = [azurerm_user_assigned_identity.machine.id, ]
  tags            = local.branch1_tags

  interfaces = [
    {
      name               = "${local.branch1_prefix}dns-main"
      subnet_id          = module.branch1.subnets["MainSubnet"].id
      private_ip_address = local.branch1_dns_addr
      create_public_ip   = true
    },
  ]
}

####################################################
# nva
####################################################

locals {
  branch1_network       = cidrhost(local.branch1_subnets["MainSubnet"].address_prefixes[0], 0)
  branch1_mask          = cidrnetmask(local.branch1_subnets["MainSubnet"].address_prefixes[0])
  branch1_inverse_mask_ = [for octet in split(".", local.branch1_mask) : 255 - tonumber(octet)]
  branch1_inverse_mask  = join(".", local.branch1_inverse_mask_)
}

# nva
#----------------------------

locals {
  branch1_nva_route_map_onprem      = "ONPREM"
  branch1_nva_route_map_azure       = "AZURE"
  branch1_nva_route_map_block_azure = "BLOCK_HUB_GW_SUBNET"
  branch1_nva_init = templatefile("../../scripts/cisco-csr-1000v.sh", {
    LOCAL_ASN   = local.branch1_nva_asn
    LOOPBACK0   = local.branch1_nva_loopback0
    LOOPBACKS   = {}
    CRYPTO_ADDR = local.branch1_nva_untrust_addr
    VPN_PSK     = local.psk

    PREFIX_LISTS = [
      "ip prefix-list ${local.branch1_nva_route_map_block_azure} deny ${local.hub1_subnets["GatewaySubnet"].address_prefixes[0]}",
      "ip prefix-list ${local.branch1_nva_route_map_block_azure} permit 0.0.0.0/0 le 32",
    ]

    NAT_ACL = [
      #"permit ip ${local.branch1_network} ${local.branch1_mask} any",
      # "permit ip 10.0.0.0 0.255.255.255 any",
      # "permit ip 172.16.0.0 0.15.255.255 any",
      # "permit ip 192.168.0.0 0.0.255.255 any"
    ]

    ROUTE_MAPS = [
      "route-map ${local.branch1_nva_route_map_onprem} permit 100",
      "match ip address prefix-list all",
      "set as-path prepend ${local.branch1_nva_asn} ${local.branch1_nva_asn} ${local.branch1_nva_asn}",

      "route-map ${local.branch1_nva_route_map_azure} permit 110",
      "match ip address prefix-list all",
    ]

    TUNNELS = [
      {
        ike = {
          name    = "Tunnel0"
          address = cidrhost(local.branch1_nva_tun_range0, 1)
          mask    = cidrnetmask(local.branch1_nva_tun_range0)
          source  = local.branch1_nva_untrust_addr
          dest    = module.vhub1.vpngw_public_ip0
        },
        ipsec = {
          peer_ip = module.vhub1.vpngw_public_ip0
          psk     = local.psk
        }
      },
      {
        ike = {
          name    = "Tunnel1"
          address = cidrhost(local.branch1_nva_tun_range1, 1)
          mask    = cidrnetmask(local.branch1_nva_tun_range1)
          source  = local.branch1_nva_untrust_addr
          dest    = module.vhub1.vpngw_public_ip1
        },
        ipsec = {
          peer_ip = module.vhub1.vpngw_public_ip1
          psk     = local.psk
        }
      },
      {
        ike = {
          name    = "Tunnel2"
          address = cidrhost(local.branch1_nva_tun_range2, 1)
          mask    = cidrnetmask(local.branch1_nva_tun_range2)
          source  = local.branch1_nva_untrust_addr
          dest    = local.branch3_nva_untrust_addr
        },
        ipsec = {
          peer_ip = local.branch3_nva_untrust_addr
          psk     = local.psk
        }
      },
    ]

    STATIC_ROUTES = [
      { network = "0.0.0.0", mask = "0.0.0.0", next_hop = local.branch1_untrust_default_gw },
      { network = module.vhub1.vpngw_bgp_ip0, mask = "255.255.255.255", next_hop = "Tunnel0" },
      { network = module.vhub1.vpngw_bgp_ip1, mask = "255.255.255.255", next_hop = "Tunnel1" },
      { network = local.branch3_nva_loopback0, mask = "255.255.255.255", next_hop = "Tunnel2" },
      {
        network  = local.branch1_network
        mask     = local.branch1_mask
        next_hop = local.branch1_trust_default_gw
      },
    ]

    BGP_SESSIONS = [
      {
        peer_asn        = module.vhub1.bgp_asn,
        peer_ip         = module.vhub1.vpngw_bgp_ip0,
        source_loopback = true
        ebgp_multihop   = true
        route_maps = [
          { direction = "out", name = local.branch1_nva_route_map_azure },
        ]
      },
      {
        peer_asn        = module.vhub1.bgp_asn
        peer_ip         = module.vhub1.vpngw_bgp_ip1
        source_loopback = true
        ebgp_multihop   = true
        route_maps = [
          { direction = "out", name = local.branch1_nva_route_map_azure },
        ]
      },
      {
        peer_asn        = local.branch3_nva_asn
        peer_ip         = local.branch3_nva_loopback0
        source_loopback = true
        ebgp_multihop   = true
        route_maps = [
          { direction = "out", name = local.branch1_nva_route_map_onprem }
        ]
      },
    ]

    BGP_ADVERTISED_NETWORKS = [
      {
        network = cidrhost(local.branch1_subnets["MainSubnet"].address_prefixes[0], 0)
        mask    = cidrnetmask(local.branch1_subnets["MainSubnet"].address_prefixes[0])
      },
    ]
  })
}

module "branch1_nva" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.branch1_prefix}nva"
  location        = local.branch1_location
  storage_account = module.common.storage_accounts["region1"]
  custom_data     = base64encode(local.branch1_nva_init)
  identity_ids    = [azurerm_user_assigned_identity.machine.id, ]
  tags            = local.branch1_tags
  source_image    = "cisco-csr-1000v"

  enable_ip_forwarding = true
  interfaces = [
    {
      name               = "${local.branch1_prefix}nva-untrust-nic"
      subnet_id          = module.branch1.subnets["UntrustSubnet"].id
      private_ip_address = local.branch1_nva_untrust_addr
      public_ip_id       = azurerm_public_ip.branch1_nva_pip.id
    },
    {
      name               = "${local.branch1_prefix}nva-trust-nic"
      subnet_id          = module.branch1.subnets["TrustSubnet"].id
      private_ip_address = local.branch1_nva_trust_addr
    },
  ]
  depends_on = [module.branch1]
}

####################################################
# workload
####################################################

locals {
  branch1_vm_init = templatefile("../../scripts/server.sh", {
    USER_ASSIGNED_ID          = azurerm_user_assigned_identity.machine.id
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
    ENABLE_TRAFFIC_GEN        = true
  })
}

module "branch1_vm" {
  source          = "../../modules/virtual-machine-linux"
  resource_group  = azurerm_resource_group.rg.name
  name            = "${local.branch1_prefix}vm"
  computer_name   = "vm"
  location        = local.branch1_location
  storage_account = module.common.storage_accounts["region1"]
  dns_servers     = [local.branch1_dns_addr, ]
  custom_data     = base64encode(local.branch1_vm_init)
  identity_ids    = [azurerm_user_assigned_identity.machine.id, ]
  tags            = local.branch1_tags

  interfaces = [
    {
      name               = "${local.branch1_prefix}vm-main-nic"
      subnet_id          = module.branch1.subnets["MainSubnet"].id
      private_ip_address = local.branch1_vm_addr
      create_public_ip   = true
    },
  ]
  depends_on = [
    module.branch1,
    module.branch1_dns,
    module.branch1_nva,
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
      next_hop_in_ip_address = local.branch1_nva_trust_addr
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
    module.branch1,
    module.branch1_dns,
    module.branch1_nva,
  ]
}

####################################################
# output files
####################################################

locals {
  branch1_files = {
    "output/branch1-nva.sh" = local.branch1_nva_init
    "output/branch1-vm.sh"  = local.branch1_vm_init
  }
}

resource "local_file" "branch1_files" {
  for_each = local.branch1_files
  filename = each.key
  content  = each.value
}
