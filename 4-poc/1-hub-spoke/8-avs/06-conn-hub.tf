
####################################################
# core1
####################################################

# vnet peering
#----------------------------

# core1-to-hub
# using remote gw transit for this peering (nva bypass)

resource "azurerm_virtual_network_peering" "core1_to_hub_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-core1-to-hub-peering"
  virtual_network_name         = module.core1.vnet.name
  remote_virtual_network_id    = module.hub.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
  depends_on = [
    module.hub.vpngw
  ]
}

# hub-to-core1
# remote gw transit

resource "azurerm_virtual_network_peering" "hub_to_core1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub-to-core1-peering"
  virtual_network_name         = module.hub.vnet.name
  remote_virtual_network_id    = module.core1.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    module.hub.vpngw
  ]
}

# udr
#----------------------------

module "core1_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.core1_prefix}main"
  location               = local.core1_location
  subnet_id              = module.core1.subnets["${local.core1_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub_nva_ilb_addr
  destinations = concat(
    ["0.0.0.0/0"],
    #local.udr_destinations_region1
  )
}

####################################################
# core2
####################################################

# vnet peering
#----------------------------

# core2-to-hub

resource "azurerm_virtual_network_peering" "core2_to_hub_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-core2-to-hub-peering"
  virtual_network_name         = module.core2.vnet.name
  remote_virtual_network_id    = module.hub.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
  depends_on = [
    module.hub.vpngw
  ]
}

# hub-to-core2

resource "azurerm_virtual_network_peering" "hub_to_core2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub-to-core2-peering"
  virtual_network_name         = module.hub.vnet.name
  remote_virtual_network_id    = module.core2.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    module.hub.vpngw
  ]
}

# udr
#----------------------------

module "core2_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.core2_prefix}main"
  location               = local.core2_location
  subnet_id              = module.core2.subnets["${local.core2_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub_nva_ilb_addr
  destinations = concat(
    ["0.0.0.0/0"],
    #local.udr_destinations_region1
  )
}

####################################################
# yellow
####################################################

# vnet peering
#----------------------------

# yellow-to-hub
# using remote gw transit for this peering (nva bypass)

resource "azurerm_virtual_network_peering" "yellow_to_hub_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-yellow-to-hub-peering"
  virtual_network_name         = module.yellow.vnet.name
  remote_virtual_network_id    = module.hub.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = true
  depends_on = [
    module.hub.vpngw
  ]
}

# hub-to-yellow
# remote gw transit

resource "azurerm_virtual_network_peering" "hub_to_yellow_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub-to-yellow-peering"
  virtual_network_name         = module.hub.vnet.name
  remote_virtual_network_id    = module.yellow.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  depends_on = [
    module.hub.vpngw
  ]
}

# udr
#----------------------------

module "yellow_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.yellow_prefix}main"
  location               = local.yellow_location
  subnet_id              = module.yellow.subnets["${local.yellow_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub_nva_ilb_addr
  destinations = concat(
    ["0.0.0.0/0"],
    #local.udr_destinations_region1
  )
}

####################################################
# hub
####################################################

# udr
#----------------------------

module "hub1_udr_gateway" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub_prefix}gateway"
  location               = local.hub_location
  subnet_id              = module.hub.subnets["GatewaySubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub_nva_ilb_addr
  destinations = concat(
    local.udr_destinations_region1
  )
}

module "hub_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub_prefix}main"
  location               = local.hub_location
  subnet_id              = module.hub.subnets["${local.hub_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub_nva_ilb_addr
  destinations = concat(
    ["0.0.0.0/0"],
    #local.udr_destinations_region1
  )
}

# nva
#----------------------------

locals {
  hub_router_route_map_name_nh = "NEXT-HOP"
  hub_router_init = templatefile("../../scripts/nva-hub.sh", {
    LOCAL_ASN = local.hub_nva_asn
    LOOPBACK0 = local.hub_nva_loopback0
    LOOPBACKS = {
      Loopback1 = local.hub_nva_ilb_addr
    }
    INT_ADDR = local.hub_nva_addr
    VPN_PSK  = local.psk

    ROUTE_MAPS = []
    TUNNELS    = []

    MASQUERADE = [
      {
        interface = "GigabitEthernet1"
        access_list = [
          "ip access-list standard NAT_ACL",
          "10 permit ip 10.0.0.0 0.0.0.255 any",
          "20 permit ip 192.168.0.0 0.0.255.255 any",
          "30 permit ip 172.16.0.0 0.15.255.255 any",
          "ip nat inside source list NAT_ACL interface GigabitEthernet1 overload"
        ]
      }
    ]

    STATIC_ROUTES = [
      { network = "0.0.0.0", mask = "0.0.0.0", next_hop = local.hub_default_gw_nva },
      { network = local.hub_ars_bgp0, mask = "255.255.255.255", next_hop = local.hub_default_gw_nva },
      { network = local.hub_ars_bgp1, mask = "255.255.255.255", next_hop = local.hub_default_gw_nva },
      {
        network  = cidrhost(local.nva_aggregate, 0)
        mask     = cidrnetmask(local.nva_aggregate)
        next_hop = local.hub_default_gw_nva
      }
    ]

    BGP_SESSIONS = [
      {
        peer_asn      = local.hub_ars_bgp_asn
        peer_ip       = local.hub_ars_bgp0
        as_override   = false
        ebgp_multihop = true
        route_map     = {}
      },
      {
        peer_asn      = local.hub_ars_bgp_asn
        peer_ip       = local.hub_ars_bgp1
        as_override   = false
        ebgp_multihop = true
        route_map     = {}
      },
    ]
    BGP_ADVERTISED_NETWORKS = [
      {
        network = cidrhost(local.nva_aggregate, 0)
        mask    = cidrnetmask(local.nva_aggregate)
      },
    ]
  })
}

module "hub_nva" {
  source               = "../../modules/csr-hub"
  resource_group       = azurerm_resource_group.rg.name
  name                 = "${local.hub_prefix}nva"
  location             = local.hub_location
  enable_ip_forwarding = true
  enable_public_ip     = true
  subnet               = module.hub.subnets["${local.hub_prefix}nva"].id
  private_ip           = local.hub_nva_addr
  storage_account      = azurerm_storage_account.region1
  admin_username       = local.username
  admin_password       = local.password
  custom_data          = base64encode(local.hub_router_init)
}

####################################################
# ars
####################################################

resource "azurerm_route_server_bgp_connection" "hub_ars_bgp_conn" {
  name            = "${local.hub_prefix}ars-bgp-conn"
  route_server_id = module.hub.ars.id
  peer_asn        = local.hub_nva_asn
  peer_ip         = local.hub_nva_addr
}

####################################################
# output files
####################################################

locals {
  hub_files = {
    "output/hub-nva.sh" = local.hub_router_init
  }
}

resource "local_file" "hub_files" {
  for_each = local.hub_files
  filename = each.key
  content  = each.value
}
