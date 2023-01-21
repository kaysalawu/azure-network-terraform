
####################################################
# spoke4
####################################################

# vnet peering
#----------------------------

# spoke4-to-hub2
# using remote gw transit for this peering (nva bypass)

resource "azurerm_virtual_network_peering" "spoke4_to_hub2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke4-to-hub2-peering"
  virtual_network_name         = module.spoke4.vnet.name
  remote_virtual_network_id    = module.hub2.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
  depends_on = [
    module.hub2.vpngw
  ]
}

# hub2-to-spoke4
# remote gw transit

resource "azurerm_virtual_network_peering" "hub2_to_spoke4_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub2-to-spoke4-peering"
  virtual_network_name         = module.hub2.vnet.name
  remote_virtual_network_id    = module.spoke4.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    module.hub2.vpngw
  ]
}

# routes
#----------------------------

# route table

resource "azurerm_route_table" "rt_spoke4" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}-rt-spoke4"
  location            = local.region2

  disable_bgp_route_propagation = false
}

# udr

locals {
  rt_spoke4_routes = {
    "10-8" = "10.0.0.0/8",
  }
}

resource "azurerm_route" "spoke4_routes_hub2" {
  for_each               = local.rt_spoke4_routes
  name                   = "${local.prefix}-${each.key}-route-hub2"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.rt_spoke4.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_nva_ilb_addr
}

# association

resource "azurerm_subnet_route_table_association" "spoke4_routes_hub2" {
  subnet_id      = module.spoke4.subnets["${local.spoke4_prefix}main"].id
  route_table_id = azurerm_route_table.rt_spoke4.id
  lifecycle {
    ignore_changes = all
  }
}

####################################################
# spoke5
####################################################

# vnet peering
#----------------------------

# spoke5-to-hub2

resource "azurerm_virtual_network_peering" "spoke5_to_hub2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke5-to-hub2-peering"
  virtual_network_name         = module.spoke5.vnet.name
  remote_virtual_network_id    = module.hub2.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
  depends_on = [
    module.hub2.vpngw
  ]
}

# hub2-to-spoke5

resource "azurerm_virtual_network_peering" "hub2_to_spoke5_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub2-to-spoke5-peering"
  virtual_network_name         = module.hub2.vnet.name
  remote_virtual_network_id    = module.spoke5.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    module.hub2.vpngw
  ]
}

# routes
#----------------------------

# route table

resource "azurerm_route_table" "rt_spoke5" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}-rt-spoke5"
  location            = local.region2

  disable_bgp_route_propagation = false
}

# udr

locals {
  rt_spoke5_routes = {
    "10-8" = "10.0.0.0/8",
  }
}

resource "azurerm_route" "spoke5_routes_hub2" {
  for_each               = local.rt_spoke5_routes
  name                   = "${local.prefix}-${each.key}-route-hub2"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.rt_spoke5.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_nva_ilb_addr
}

# association

resource "azurerm_subnet_route_table_association" "spoke5_routes_hub2" {
  subnet_id      = module.spoke5.subnets["${local.spoke5_prefix}main"].id
  route_table_id = azurerm_route_table.rt_spoke5.id
  lifecycle {
    ignore_changes = all
  }
}

####################################################
# branch3
####################################################

# local gw
#----------------------------

resource "azurerm_local_network_gateway" "hub2_branch3_lng" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}branch3-lng"
  location            = local.hub2_location
  gateway_address     = azurerm_public_ip.branch3_nva_pip.ip_address
  address_space       = ["${local.branch3_nva_loopback0}/32", ]
  bgp_settings {
    asn                 = local.branch3_nva_asn
    bgp_peering_address = local.branch3_nva_loopback0
  }
}

# lng connection
#----------------------------

resource "azurerm_virtual_network_gateway_connection" "hub2_branch3_lng" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub2_prefix}branch3-lng-conn"
  location                   = local.hub2_location
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = module.hub2.vpngw.id
  local_network_gateway_id   = azurerm_local_network_gateway.hub2_branch3_lng.id
  shared_key                 = local.psk
}

####################################################
# branch2
####################################################

# nva
#----------------------------

locals {
  hub2_router_route_map_name_nh = "NEXT-HOP"
  hub2_router_init = templatefile("../../scripts/nva-hub.sh", {
    LOCAL_ASN = local.hub2_nva_asn
    LOOPBACK0 = local.hub2_nva_loopback0
    LOOPBACKS = {
      Loopback1 = local.hub2_nva_ilb_addr
    }
    INT_ADDR = local.hub2_nva_addr
    VPN_PSK  = local.psk

    ROUTE_MAPS = [
      {
        name   = local.hub2_router_route_map_name_nh
        action = "permit"
        rule   = 100
        commands = [
          "match ip address prefix-list all",
          "set ip next-hop ${local.hub2_nva_ilb_addr}"
        ]
      }
    ]

    TUNNELS = [
      {
        ike = {
          name    = "Tunnel0"
          address = cidrhost(local.hub2_nva_tun_range0, 1)
          mask    = cidrnetmask(local.hub2_nva_tun_range0)
          source  = local.hub2_nva_addr
          dest    = local.hub1_nva_addr
        },
        ipsec = {
          peer_ip = local.hub1_nva_addr
          psk     = local.psk
        }
      },
    ]

    STATIC_ROUTES = [
      { network = "0.0.0.0", mask = "0.0.0.0", next_hop = local.hub2_default_gw_nva },
      { network = local.hub1_nva_loopback0, mask = "255.255.255.255", next_hop = "Tunnel0" },
      { network = local.hub1_nva_addr, mask = "255.255.255.255", next_hop = local.hub2_default_gw_nva },
      { network = local.hub2_ars_bgp0, mask = "255.255.255.255", next_hop = local.hub2_default_gw_nva },
      { network = local.hub2_ars_bgp1, mask = "255.255.255.255", next_hop = local.hub2_default_gw_nva },
    ]

    BGP_SESSIONS = [
      {
        peer_asn      = local.hub2_ars_bgp_asn
        peer_ip       = local.hub2_ars_bgp0
        as_override   = true
        ebgp_multihop = true
        route_map = {
          name      = local.hub2_router_route_map_name_nh
          direction = "out"
        }
      },
      {
        peer_asn      = local.hub2_ars_bgp_asn
        peer_ip       = local.hub2_ars_bgp1
        as_override   = true
        ebgp_multihop = true
        route_map = {
          name      = local.hub2_router_route_map_name_nh
          direction = "out"
        }
      },
      {
        peer_asn        = local.hub1_nva_asn
        peer_ip         = local.hub1_nva_loopback0
        next_hop_self   = true
        source_loopback = true
        route_map       = {}
      },
    ]

    BGP_ADVERTISED_NETWORKS = []
  })
}

module "hub2_nva" {
  source               = "../../modules/csr-hub"
  resource_group       = azurerm_resource_group.rg.name
  name                 = "${local.hub2_prefix}nva"
  location             = local.hub2_location
  enable_ip_forwarding = true
  enable_public_ip     = true
  subnet               = module.hub2.subnets["${local.hub2_prefix}nva"].id
  private_ip           = local.hub2_nva_addr
  storage_account      = azurerm_storage_account.region2
  admin_username       = local.username
  admin_password       = local.password
  custom_data          = base64encode(local.hub2_router_init)
}

####################################################
# ars
####################################################

resource "azurerm_route_server_bgp_connection" "hub2_ars_bgp_conn" {
  name            = "${local.hub2_prefix}ars-bgp-conn"
  route_server_id = module.hub2.ars.id
  peer_asn        = local.hub2_nva_asn
  peer_ip         = local.hub2_nva_addr
}

####################################################
# output files
####################################################

locals {
  hub2_files = {
    "output/hub2-nva.sh" = local.hub2_router_init
  }
}

resource "local_file" "hub2_files" {
  for_each = local.hub2_files
  filename = each.key
  content  = each.value
}
