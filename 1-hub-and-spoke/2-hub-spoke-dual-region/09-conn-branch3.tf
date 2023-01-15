
####################################################
# branch3
####################################################

# router
#----------------------------

locals {
  branch3_nva_init = templatefile("../../scripts/nva-branch.sh", {
    LOCAL_ASN = local.branch3_nva_asn
    LOOPBACK0 = local.branch3_nva_loopback0
    LOOPBACKS = {}
    EXT_ADDR  = local.branch3_nva_ext_addr
    VPN_PSK   = local.psk

    ROUTE_MAPS = []

    TUNNELS = [
      {
        ike = {
          name    = "Tunnel0"
          address = cidrhost(local.branch3_nva_tun_range0, 1)
          mask    = cidrnetmask(local.branch3_nva_tun_range0)
          source  = local.branch3_nva_ext_addr
          dest    = module.hub2.vpngw_pip0.ip_address
        },
        ipsec = {
          peer_ip = module.hub2.vpngw_pip0.ip_address
          psk     = local.psk
        }
      },
      {
        ike = {
          name    = "Tunnel1"
          address = cidrhost(local.branch3_nva_tun_range1, 1)
          mask    = cidrnetmask(local.branch3_nva_tun_range1)
          source  = local.branch3_nva_ext_addr
          dest    = module.hub2.vpngw_pip1.ip_address
        },
        ipsec = {
          peer_ip = module.hub2.vpngw_pip1.ip_address
          psk     = local.psk
        }
      },
    ]

    STATIC_ROUTES = [
      { network = "0.0.0.0", mask = "0.0.0.0", next_hop = local.branch3_ext_default_gw },
      { network = local.hub2_vpngw_bgp0, mask = "255.255.255.255", next_hop = "Tunnel0" },
      { network = local.hub2_vpngw_bgp1, mask = "255.255.255.255", next_hop = "Tunnel1" },
      {
        network  = cidrhost(local.branch3_subnets["${local.branch3_prefix}main"].address_prefixes[0], 0)
        mask     = cidrnetmask(local.branch3_subnets["${local.branch3_prefix}main"].address_prefixes[0])
        next_hop = local.branch3_int_default_gw
      },
    ]

    BGP_SESSIONS = [
      {
        peer_asn        = local.hub2_vpngw_asn
        peer_ip         = local.hub2_vpngw_bgp0
        source_loopback = true
        ebgp_multihop   = true
        route_map       = {}
      },
      {
        peer_asn        = local.hub2_vpngw_asn
        peer_ip         = local.hub2_vpngw_bgp1
        source_loopback = true
        ebgp_multihop   = true
        route_map       = {}
      },
    ]

    BGP_ADVERTISED_NETWORKS = [
      {
        network = cidrhost(local.branch3_subnets["${local.branch3_prefix}main"].address_prefixes[0], 0)
        mask    = cidrnetmask(local.branch3_subnets["${local.branch3_prefix}main"].address_prefixes[0])
      },
    ]
  })
}

# addresses

resource "azurerm_public_ip" "branch3_nva_pip" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch3_prefix}nva-pip"
  location            = local.branch3_location
  sku                 = "Standard"
  allocation_method   = "Static"
}

# vm

module "branch3_nva" {
  source               = "../../modules/csr-branch"
  resource_group       = azurerm_resource_group.rg.name
  name                 = "${local.branch3_prefix}nva"
  location             = local.branch3_location
  enable_ip_forwarding = true
  enable_public_ip     = true
  subnet_ext           = module.branch3.subnets["${local.branch3_prefix}ext"].id
  subnet_int           = module.branch3.subnets["${local.branch3_prefix}int"].id
  private_ip_ext       = local.branch3_nva_ext_addr
  private_ip_int       = local.branch3_nva_int_addr
  public_ip            = azurerm_public_ip.branch3_nva_pip.id
  storage_account      = azurerm_storage_account.region2
  admin_username       = local.username
  admin_password       = local.password
  custom_data          = base64encode(local.branch3_nva_init)
}

# udr
#----------------------------

# route table

resource "azurerm_route_table" "branch3_rt" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.branch3_prefix}rt"
  location            = local.region2

  disable_bgp_route_propagation = true
}

# routes

resource "azurerm_route" "branch3_default_route_azure" {
  name                   = "${local.branch3_prefix}default-route-azure"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.branch3_rt.name
  address_prefix         = "10.0.0.0/8"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.branch3_nva_int_addr
}

# association

resource "azurerm_subnet_route_table_association" "branch3_default_route_azure" {
  subnet_id      = module.branch3.subnets["${local.branch3_prefix}main"].id
  route_table_id = azurerm_route_table.branch3_rt.id
  lifecycle {
    ignore_changes = all
  }
}

####################################################
# output files
####################################################

locals {
  branch3_files = {
    "output/branch3-nva.sh" = local.branch3_nva_init
  }
}

resource "local_file" "branch3_files" {
  for_each = local.branch3_files
  filename = each.key
  content  = each.value
}
