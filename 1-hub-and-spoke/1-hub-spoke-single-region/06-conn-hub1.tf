
####################################################
# spoke1
####################################################

# vnet peering
#----------------------------

# spoke1-to-hub1
# using remote gw transit for this peering (nva bypass)

resource "azurerm_virtual_network_peering" "spoke1_to_hub1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke1-to-hub1-peering"
  virtual_network_name         = module.spoke1.vnet.name
  remote_virtual_network_id    = module.hub1.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
  depends_on = [
    module.hub1.vpngw
  ]
}

# hub1-to-spoke1
# remote gw transit

resource "azurerm_virtual_network_peering" "hub1_to_spoke1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub1-to-spoke1-peering"
  virtual_network_name         = module.hub1.vnet.name
  remote_virtual_network_id    = module.spoke1.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    module.hub1.vpngw
  ]
}

# routes
#----------------------------

# route table

resource "azurerm_route_table" "rt_spoke1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}-rt-spoke1"
  location            = local.region1

  disable_bgp_route_propagation = false
}

# udr

locals {
  rt_spoke1_routes = {
    "10-8" = "10.0.0.0/8",
  }
}

resource "azurerm_route" "spoke1_routes_hub1" {
  for_each               = local.rt_spoke1_routes
  name                   = "${local.prefix}-${each.key}-route-hub1"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.rt_spoke1.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub1_nva_ilb_addr
}

# association

resource "azurerm_subnet_route_table_association" "spoke1_routes_hub1" {
  subnet_id      = module.spoke1.subnets["${local.spoke1_prefix}main"].id
  route_table_id = azurerm_route_table.rt_spoke1.id
  lifecycle {
    ignore_changes = all
  }
}

####################################################
# spoke2
####################################################

# vnet peering
#----------------------------

# spoke2-to-hub1

resource "azurerm_virtual_network_peering" "spoke2_to_hub1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke2-to-hub1-peering"
  virtual_network_name         = module.spoke2.vnet.name
  remote_virtual_network_id    = module.hub1.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
  depends_on = [
    module.hub1.vpngw
  ]
}

# hub1-to-spoke2

resource "azurerm_virtual_network_peering" "hub1_to_spoke2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub1-to-spoke2-peering"
  virtual_network_name         = module.hub1.vnet.name
  remote_virtual_network_id    = module.spoke2.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    module.hub1.vpngw
  ]
}

# routes
#----------------------------

# route table

resource "azurerm_route_table" "rt_spoke2" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.prefix}-rt-spoke2"
  location            = local.region1

  disable_bgp_route_propagation = false
}

# udr

locals {
  rt_spoke2_routes = {
    "10-8" = "10.0.0.0/8",
  }
}

resource "azurerm_route" "spoke2_routes_hub1" {
  for_each               = local.rt_spoke2_routes
  name                   = "${local.prefix}-${each.key}-route-hub1"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.rt_spoke2.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub1_nva_ilb_addr
}

# association

resource "azurerm_subnet_route_table_association" "spoke2_routes_hub1" {
  subnet_id      = module.spoke2.subnets["${local.spoke2_prefix}main"].id
  route_table_id = azurerm_route_table.rt_spoke2.id
  lifecycle {
    ignore_changes = all
  }
}

####################################################
# branch1
####################################################

# lng
#----------------------------

resource "azurerm_local_network_gateway" "hub1_branch1_lng" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}branch1-lng"
  location            = local.hub1_location
  gateway_address     = azurerm_public_ip.branch1_nva_pip.ip_address
  address_space       = ["${local.branch1_nva_loopback0}/32", ]
  bgp_settings {
    asn                 = local.branch1_nva_asn
    bgp_peering_address = local.branch1_nva_loopback0
  }
}

# lng connection
#----------------------------

resource "azurerm_virtual_network_gateway_connection" "hub1_branch1_lng" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub1_prefix}branch1-lng-conn"
  location                   = local.hub1_location
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = module.hub1.vpngw.id
  local_network_gateway_id   = azurerm_local_network_gateway.hub1_branch1_lng.id
  shared_key                 = local.psk
}

####################################################
# branch2
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

    BGP_ADVERTISED_NETWORKS = []
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
