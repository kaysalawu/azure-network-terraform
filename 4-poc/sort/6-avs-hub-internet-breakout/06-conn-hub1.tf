
####################################################
# hub1
####################################################

# udr
#----------------------------

module "branch1_udr_gateway" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub1_prefix}gateway"
  location               = local.hub1_location
  subnet_id              = module.hub1.subnets["GatewaySubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub1_nva_ilb_addr
  destinations = concat(
    local.udr_destinations_region1
  )
}

module "hub1_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub1_prefix}main"
  location               = local.hub1_location
  subnet_id              = module.hub1.subnets["${local.hub1_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub1_nva_ilb_addr
  destinations = concat(
    local.udr_destinations_region1
  )
}

####################################################
# hub1
####################################################

# nva
#----------------------------

locals {
  hub1_router_route_map_name_nh = "NEXT-HOP"
  hub1_router_init = templatefile("../../scripts/nva-hub.sh", {
    LOCAL_ASN = local.hub1_nva_asn
    LOOPBACK0 = local.hub1_nva_loopback0
    LOOPBACKS = {
      Loopback1 = local.hub1_nva_ilb_addr
    }
    INT_ADDR = local.hub1_nva_addr
    VPN_PSK  = local.psk

    ROUTE_MAPS = [
      {
        name   = local.hub1_router_route_map_name_nh
        action = "permit"
        rule   = 100
        commands = [
          "match ip address prefix-list all",
          "set ip next-hop ${local.hub1_nva_ilb_addr}"
        ]
      }
    ]

    TUNNELS = []

    STATIC_ROUTES = [
      { network = "0.0.0.0", mask = "0.0.0.0", next_hop = local.hub1_default_gw_nva },
      { network = local.hub1_ars_bgp0, mask = "255.255.255.255", next_hop = local.hub1_default_gw_nva },
      { network = local.hub1_ars_bgp1, mask = "255.255.255.255", next_hop = local.hub1_default_gw_nva },
      {
        network  = cidrhost(local.supernet, 0),
        mask     = cidrnetmask(local.supernet),
        next_hop = local.hub1_default_gw_nva
      },
    ]

    BGP_SESSIONS = [
      {
        peer_asn      = local.hub1_ars_bgp_asn
        peer_ip       = local.hub1_ars_bgp0
        as_override   = true
        ebgp_multihop = true
        route_map = {
          name      = local.hub1_router_route_map_name_nh
          direction = "out"
        }
      },
      {
        peer_asn      = local.hub1_ars_bgp_asn
        peer_ip       = local.hub1_ars_bgp1
        as_override   = true
        ebgp_multihop = true
        route_map = {
          name      = local.hub1_router_route_map_name_nh
          direction = "out"
        }
      },
    ]
    BGP_ADVERTISED_NETWORKS = [
      {
        network = cidrhost(local.supernet, 0)
        mask    = cidrnetmask(local.supernet)
      },
    ]
  })
}

module "hub1_nva" {
  source               = "../../modules/csr-hub"
  resource_group       = azurerm_resource_group.rg.name
  name                 = "${local.hub1_prefix}nva"
  location             = local.hub1_location
  enable_ip_forwarding = true
  enable_public_ip     = true
  subnet               = module.hub1.subnets["${local.hub1_prefix}nva"].id
  private_ip           = local.hub1_nva_addr
  storage_account      = azurerm_storage_account.region1
  admin_username       = local.username
  admin_password       = local.password
  custom_data          = base64encode(local.hub1_router_init)
}

####################################################
# ars
####################################################

resource "azurerm_route_server_bgp_connection" "hub1_ars_bgp_conn" {
  name            = "${local.hub1_prefix}ars-bgp-conn"
  route_server_id = module.hub1.ars.id
  peer_asn        = local.hub1_nva_asn
  peer_ip         = local.hub1_nva_addr
}

####################################################
# output files
####################################################

locals {
  hub1_files = {
    "output/hub1-nva.sh" = local.hub1_router_init
  }
}

resource "local_file" "hub1_files" {
  for_each = local.hub1_files
  filename = each.key
  content  = each.value
}
