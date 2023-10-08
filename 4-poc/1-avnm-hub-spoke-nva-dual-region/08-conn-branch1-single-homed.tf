
####################################################
# branch1
####################################################

locals {
  branch1_network       = cidrhost(local.branch1_subnets["${local.branch1_prefix}main"].address_prefixes[0], 0)
  branch1_mask          = cidrnetmask(local.branch1_subnets["${local.branch1_prefix}main"].address_prefixes[0])
  branch1_inverse_mask_ = [for octet in split(".", local.branch1_mask) : 255 - tonumber(octet)]
  branch1_inverse_mask  = join(".", local.branch1_inverse_mask_)
}

# nva
#----------------------------

locals {
  branch1_nva_route_map_name_nh = "NEXT-HOP"
  branch1_nva_init = templatefile("../../scripts/cisco-branch.sh", {
    LOCAL_ASN = local.branch1_nva_asn
    LOOPBACK0 = local.branch1_nva_loopback0
    LOOPBACKS = {}
    EXT_ADDR  = local.branch1_nva_ext_addr
    VPN_PSK   = local.psk

    NAT_ACL_PREFIXES = [
      { network = local.branch1_network, inverse_mask = local.branch1_inverse_mask }
    ]

    ROUTE_MAPS = [
      {
        name   = local.branch1_nva_route_map_name_nh
        action = "permit"
        rule   = 100
        commands = [
          "match ip address prefix-list all",
          "set as-path prepend ${local.branch1_nva_asn} ${local.branch1_nva_asn} ${local.branch1_nva_asn}"
        ]
      }
    ]

    TUNNELS = [
      {
        ike = {
          name    = "Tunnel0"
          address = cidrhost(local.branch1_nva_tun_range0, 1)
          mask    = cidrnetmask(local.branch1_nva_tun_range0)
          source  = local.branch1_nva_ext_addr
          dest    = module.hub1.vpngw_public_ip0
        },
        ipsec = {
          peer_ip = module.hub1.vpngw_public_ip0
          psk     = local.psk
        }
      },
      {
        ike = {
          name    = "Tunnel1"
          address = cidrhost(local.branch1_nva_tun_range1, 1)
          mask    = cidrnetmask(local.branch1_nva_tun_range1)
          source  = local.branch1_nva_ext_addr
          dest    = module.hub1.vpngw_public_ip1
        },
        ipsec = {
          peer_ip = module.hub1.vpngw_public_ip1
          psk     = local.psk
        }
      },
      {
        ike = {
          name    = "Tunnel2"
          address = cidrhost(local.branch1_nva_tun_range2, 1)
          mask    = cidrnetmask(local.branch1_nva_tun_range2)
          source  = local.branch1_nva_ext_addr
          dest    = local.branch3_nva_ext_addr
        },
        ipsec = {
          peer_ip = local.branch3_nva_ext_addr
          psk     = local.psk
        }
      },
    ]

    STATIC_ROUTES = [
      { network = "0.0.0.0", mask = "0.0.0.0", next_hop = local.branch1_ext_default_gw },
      { network = local.hub1_vpngw_bgp_ip0, mask = "255.255.255.255", next_hop = "Tunnel0" },
      { network = local.hub1_vpngw_bgp_ip1, mask = "255.255.255.255", next_hop = "Tunnel1" },
      { network = local.branch3_nva_loopback0, mask = "255.255.255.255", next_hop = "Tunnel2" },
      {
        network  = local.branch1_network
        mask     = local.branch1_mask
        next_hop = local.branch1_int_default_gw
      },
    ]

    BGP_SESSIONS = [
      {
        peer_asn        = local.hub1_bgp_asn,
        peer_ip         = local.hub1_vpngw_bgp_ip0,
        source_loopback = true
        ebgp_multihop   = true
        route_map       = {}
      },
      {
        peer_asn        = local.hub1_bgp_asn
        peer_ip         = local.hub1_vpngw_bgp_ip1
        source_loopback = true
        ebgp_multihop   = true
        route_map       = {}
      },
      {
        peer_asn        = local.branch3_nva_asn
        peer_ip         = local.branch3_nva_loopback0
        source_loopback = true
        ebgp_multihop   = true
        route_map = {
          name      = local.branch1_nva_route_map_name_nh
          direction = "out"
        }
      },
    ]

    BGP_ADVERTISED_NETWORKS = [
      {
        network = cidrhost(local.branch1_subnets["${local.branch1_prefix}main"].address_prefixes[0], 0)
        mask    = cidrnetmask(local.branch1_subnets["${local.branch1_prefix}main"].address_prefixes[0])
      },
    ]
  })
}

module "branch1_nva" {
  source               = "../../modules/csr-branch"
  resource_group       = azurerm_resource_group.rg.name
  name                 = "${local.branch1_prefix}nva"
  location             = local.branch1_location
  enable_ip_forwarding = true
  enable_public_ip     = true
  subnet_ext           = module.branch1.subnets["${local.branch1_prefix}ext"].id
  subnet_int           = module.branch1.subnets["${local.branch1_prefix}int"].id
  private_ip_ext       = local.branch1_nva_ext_addr
  private_ip_int       = local.branch1_nva_int_addr
  public_ip            = azurerm_public_ip.branch1_nva_pip.id
  storage_account      = module.common.storage_accounts["region1"]
  admin_username       = local.username
  admin_password       = local.password
  custom_data          = base64encode(local.branch1_nva_init)
}

# udr
#----------------------------

# main

module "branch1_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.branch1_prefix}main"
  location               = local.branch1_location
  subnet_id              = module.branch1.subnets["${local.branch1_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.branch1_nva_int_addr
  destinations           = local.default_udr_destinations

  disable_bgp_route_propagation = true
}

####################################################
# output files
####################################################

locals {
  branch1_files = {
    "output/branch1-nva.sh" = local.branch1_nva_init
  }
}

resource "local_file" "branch1_files" {
  for_each = local.branch1_files
  filename = each.key
  content  = each.value
}

