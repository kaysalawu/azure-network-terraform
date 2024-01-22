
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
  tags            = local.branch1_tags

  nsg_subnet_map = {
    "MainSubnet"      = module.common.nsg_main["region2"].id
    "TrustSubnet"     = module.common.nsg_main["region2"].id
    "UntrustSubnet"   = module.common.nsg_nva["region2"].id
    "DnsServerSubnet" = module.common.nsg_main["region2"].id
  }

  config_vnet = {
    address_space = local.branch2_address_space
    subnets       = local.branch2_subnets
    dns_servers   = [local.branch2_dns_addr, ]
  }

  depends_on = [
    module.common,
  ]
}

####################################################
# dns
####################################################

module "branch2_dns" {
  source           = "../../modules/linux"
  resource_group   = azurerm_resource_group.rg.name
  prefix           = local.branch2_prefix
  name             = "dns"
  location         = local.branch2_location
  subnet           = module.branch2.subnets["MainSubnet"].id
  private_ip       = local.branch2_dns_addr
  enable_public_ip = true
  source_image     = "ubuntu-20"
  custom_data      = base64encode(local.branch_unbound_startup)
  storage_account  = module.common.storage_accounts["region2"]
  tags             = local.branch2_tags
}

####################################################
# nva
####################################################

locals {
  branch2_network       = cidrhost(local.branch2_subnets["MainSubnet"].address_prefixes[0], 0)
  branch2_mask          = cidrnetmask(local.branch2_subnets["MainSubnet"].address_prefixes[0])
  branch2_inverse_mask_ = [for octet in split(".", local.branch2_mask) : 255 - tonumber(octet)]
  branch2_inverse_mask  = join(".", local.branch2_inverse_mask_)
}

# nva
#----------------------------

locals {
  branch2_nva_route_map_onprem = "ONPREM"
  branch2_nva_route_map_azure  = "AZURE"
  branch2_nva_init = templatefile("../../scripts/cisco-branch.sh", {
    LOCAL_ASN   = local.branch2_nva_asn
    LOOPBACK0   = local.branch2_nva_loopback0
    LOOPBACKS   = {}
    CRYPTO_ADDR = local.branch2_nva_untrust_addr
    VPN_PSK     = local.psk

    NAT_ACL_PREFIXES = [
      { network = local.branch2_network, inverse_mask = local.branch2_inverse_mask }
    ]

    ROUTE_MAPS = [
      {
        name   = local.branch2_nva_route_map_onprem
        action = "permit"
        rule   = 100
        commands = [
          "match ip address prefix-list all",
          "set as-path prepend ${local.branch2_nva_asn} ${local.branch2_nva_asn} ${local.branch2_nva_asn}"
        ]
      },
      {
        name   = local.branch2_nva_route_map_azure
        action = "permit"
        rule   = 110
        commands = [
          "match ip address prefix-list all",
        ]
      }
    ]

    TUNNELS = [
      {
        ike = {
          name    = "Tunnel0"
          address = cidrhost(local.branch2_nva_tun_range0, 1)
          mask    = cidrnetmask(local.branch2_nva_tun_range0)
          source  = local.branch2_nva_untrust_addr
          dest    = module.vhub2.vpngw_public_ip0
        },
        ipsec = {
          peer_ip = module.vhub2.vpngw_public_ip0
          psk     = local.psk
        }
      },
      {
        ike = {
          name    = "Tunnel1"
          address = cidrhost(local.branch2_nva_tun_range1, 1)
          mask    = cidrnetmask(local.branch2_nva_tun_range1)
          source  = local.branch2_nva_untrust_addr
          dest    = module.vhub2.vpngw_public_ip1
        },
        ipsec = {
          peer_ip = module.vhub2.vpngw_public_ip1
          psk     = local.psk
        }
      }
    ]

    STATIC_ROUTES = [
      { network = "0.0.0.0", mask = "0.0.0.0", next_hop = local.branch2_untrust_default_gw },
      { network = module.vhub2.vpngw_bgp_ip0, mask = "255.255.255.255", next_hop = "Tunnel0" },
      { network = module.vhub2.vpngw_bgp_ip1, mask = "255.255.255.255", next_hop = "Tunnel1" },
      {
        network  = local.branch2_network
        mask     = local.branch2_mask
        next_hop = local.branch2_trust_default_gw
      },
    ]

    BGP_SESSIONS = [
      {
        peer_asn        = module.vhub2.bgp_asn,
        peer_ip         = module.vhub2.vpngw_bgp_ip0,
        source_loopback = true
        ebgp_multihop   = true
        route_maps = [
          { direction = "out", name = local.branch2_nva_route_map_azure }
        ]
      },
      {
        peer_asn        = module.vhub2.bgp_asn
        peer_ip         = module.vhub2.vpngw_bgp_ip1
        source_loopback = true
        ebgp_multihop   = true
        route_maps = [
          { direction = "out", name = local.branch2_nva_route_map_azure }
        ]
      },
    ]

    BGP_ADVERTISED_NETWORKS = [
      {
        network = cidrhost(local.branch2_subnets["MainSubnet"].address_prefixes[0], 0)
        mask    = cidrnetmask(local.branch2_subnets["MainSubnet"].address_prefixes[0])
      },
    ]
  })
}

module "branch2_nva" {
  source               = "../../modules/csr-branch"
  resource_group       = azurerm_resource_group.rg.name
  name                 = "${local.branch2_prefix}nva"
  location             = local.branch2_location
  enable_ip_forwarding = true
  enable_public_ip     = true
  subnet_ext           = module.branch2.subnets["UntrustSubnet"].id
  subnet_int           = module.branch2.subnets["TrustSubnet"].id
  private_ip_ext       = local.branch2_nva_untrust_addr
  private_ip_int       = local.branch2_nva_trust_addr
  public_ip            = azurerm_public_ip.branch2_nva_pip.id
  storage_account      = module.common.storage_accounts["region2"]
  admin_username       = local.username
  admin_password       = local.password
  custom_data          = base64encode(local.branch2_nva_init)
}

####################################################
# workload
####################################################

locals {
  branch2_vm_init = templatefile("../../scripts/server.sh", {
    TARGETS                   = local.vm_script_targets
    TARGETS_LIGHT_TRAFFIC_GEN = local.vm_script_targets
    TARGETS_HEAVY_TRAFFIC_GEN = [for target in local.vm_script_targets : target.dns if try(target.probe, false)]
    ENABLE_TRAFFIC_GEN        = true
  })
}

module "branch2_vm" {
  source           = "../../modules/linux"
  resource_group   = azurerm_resource_group.rg.name
  prefix           = local.branch2_prefix
  name             = "vm"
  location         = local.branch2_location
  subnet           = module.branch2.subnets["MainSubnet"].id
  private_ip       = local.branch2_vm_addr
  enable_public_ip = true
  source_image     = "ubuntu-20"
  custom_data      = base64encode(local.branch1_vm_init)
  storage_account  = module.common.storage_accounts["region1"]
  delay_creation   = "60s"
  tags             = local.branch2_tags

  depends_on = [
    module.branch2,
    module.branch2_dns,
    module.branch2_nva,
  ]
}

####################################################
# udr
####################################################

# main

module "branch2_udr_main" {
  source                        = "../../modules/route"
  resource_group                = azurerm_resource_group.rg.name
  prefix                        = "${local.branch2_prefix}main"
  location                      = local.branch2_location
  subnet_id                     = module.branch2.subnets["MainSubnet"].id
  next_hop_type                 = "VirtualAppliance"
  next_hop_in_ip_address        = local.branch2_nva_trust_addr
  destinations                  = local.private_prefixes_map
  delay_creation                = "90s"
  disable_bgp_route_propagation = true
  depends_on = [
    module.branch2,
    module.branch2_nva,
    module.branch2_dns,
  ]
}

####################################################
# output files
####################################################

locals {
  branch2_files = {
    "output/branch2-nva.sh" = local.branch2_nva_init
  }
}

resource "local_file" "branch2_files" {
  for_each = local.branch2_files
  filename = each.key
  content  = each.value
}

