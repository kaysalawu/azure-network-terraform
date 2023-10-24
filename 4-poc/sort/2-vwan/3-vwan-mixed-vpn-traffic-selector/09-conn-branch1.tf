
####################################################
# branch1
####################################################

# router

locals {
  branch1_nva_init = templatefile("../../scripts/nva-branch.sh", {
    LOCAL_ASN = local.branch1_nva_asn
    LOOPBACK0 = local.branch1_nva_loopback0
    LOOPBACKS = {}
    EXT_ADDR  = local.branch1_nva_ext_addr
    VPN_PSK   = local.psk

    ROUTE_MAPS = []

    TUNNELS = [
      {
        ike = {
          name    = "Tunnel0"
          address = cidrhost(local.branch1_nva_tun_range0, 1)
          mask    = cidrnetmask(local.branch1_nva_tun_range0)
          source  = local.branch1_nva_ext_addr
          dest    = local.vhub1_vpngw_pip0
        },
        ipsec = {
          peer_ip = local.vhub1_vpngw_pip0
          psk     = local.psk
        }
      },
      {
        ike = {
          name    = "Tunnel1"
          address = cidrhost(local.branch1_nva_tun_range1, 1)
          mask    = cidrnetmask(local.branch1_nva_tun_range1)
          source  = local.branch1_nva_ext_addr
          dest    = local.vhub1_vpngw_pip1
        },
        ipsec = {
          peer_ip = local.vhub1_vpngw_pip1
          psk     = local.psk
        }
      },
    ]

    STATIC_ROUTES = [
      { network = "0.0.0.0", mask = "0.0.0.0", next_hop = local.branch1_ext_default_gw },
      { network = local.vhub1_vpngw_bgp0, mask = "255.255.255.255", next_hop = "Tunnel0" },
      { network = local.vhub1_vpngw_bgp1, mask = "255.255.255.255", next_hop = "Tunnel1" },
      {
        network  = cidrhost(local.branch1_subnets["${local.branch1_prefix}main"].address_prefixes[0], 0)
        mask     = cidrnetmask(local.branch1_subnets["${local.branch1_prefix}main"].address_prefixes[0])
        next_hop = local.branch1_int_default_gw
      },
    ]

    BGP_SESSIONS = [
      {
        peer_asn        = local.vhub1_bgp_asn,
        peer_ip         = local.vhub1_vpngw_bgp0,
        source_loopback = true
        ebgp_multihop   = true
        route_map       = {}
      },
      {
        peer_asn        = local.vhub1_bgp_asn
        peer_ip         = local.vhub1_vpngw_bgp1
        source_loopback = true
        ebgp_multihop   = true
        route_map       = {}
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

# vm

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
  storage_account      = azurerm_storage_account.region1
  admin_username       = local.username
  admin_password       = local.password
  custom_data          = base64encode(local.branch1_nva_init)
}

# udr

module "branch1_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.branch1_prefix}main"
  location               = local.branch1_location
  subnet_id              = module.branch1.subnets["${local.branch1_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.branch1_nva_int_addr
  destinations           = ["10.0.0.0/8"]
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
