
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

# udr
#----------------------------

module "spoke4_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.spoke4_prefix}main"
  location               = local.spoke4_location
  subnet_id              = module.spoke4.subnets["${local.spoke4_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.hub2.firewall_private_ip
  destinations = concat(
    local.udr_destinations_region1,
    local.udr_destinations_region2
  )
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

# udr
#----------------------------

module "spoke5_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.spoke5_prefix}main"
  location               = local.spoke5_location
  subnet_id              = module.spoke5.subnets["${local.spoke5_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.hub2.firewall_private_ip
  destinations = concat(
    local.udr_destinations_region1,
    local.udr_destinations_region2
  )
}

####################################################
# branch3
####################################################

# lng
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
# hub2
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
    TUNNELS = []

    STATIC_ROUTES = [
      { network = "0.0.0.0", mask = "0.0.0.0", next_hop = local.hub2_default_gw_nva },
      { network = local.hub2_ars_bgp0, mask = "255.255.255.255", next_hop = local.hub2_default_gw_nva },
      { network = local.hub2_ars_bgp1, mask = "255.255.255.255", next_hop = local.hub2_default_gw_nva },
      { network = local.hub1_nva_loopback0, mask = "255.255.255.255", next_hop = "Tunnel0" },
      { network = local.hub1_nva_addr, mask = "255.255.255.255", next_hop = local.hub2_default_gw_nva },
      {
        network  = split("/", local.branch1_address_space[0])[0]
        mask     = cidrnetmask(local.branch1_address_space[0])
        next_hop = local.hub2_default_gw_nva
      },
      {
        network  = split("/", local.hub1_address_space[0])[0]
        mask     = cidrnetmask(local.hub1_address_space[0])
        next_hop = local.hub2_default_gw_nva
      },
      {
        network  = split("/", local.spoke1_address_space[0])[0]
        mask     = cidrnetmask(local.spoke1_address_space[0])
        next_hop = local.hub2_default_gw_nva
      },
      {
        network  = split("/", local.spoke2_address_space[0])[0]
        mask     = cidrnetmask(local.spoke2_address_space[0])
        next_hop = local.hub2_default_gw_nva
      },
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
    ]

    BGP_ADVERTISED_NETWORKS = [
      { network = split("/", local.branch1_address_space[0])[0], mask = cidrnetmask(local.branch1_address_space[0]) },
      { network = split("/", local.hub1_address_space[0])[0], mask = cidrnetmask(local.hub1_address_space[0]) },
      { network = split("/", local.spoke1_address_space[0])[0], mask = cidrnetmask(local.spoke1_address_space[0]) },
      { network = split("/", local.spoke2_address_space[0])[0], mask = cidrnetmask(local.spoke2_address_space[0]) }
    ]
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

# udr
#----------------------------

module "hub2_udr_gateway" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub2_prefix}gateway"
  location               = local.hub2_location
  subnet_id              = module.hub2.subnets["GatewaySubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.hub2.firewall_private_ip
  destinations = concat(
    local.udr_destinations_region1,
    local.udr_destinations_region2
  )
}

module "hub2_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub2_prefix}main"
  location               = local.hub2_location
  subnet_id              = module.hub2.subnets["${local.hub2_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.hub2.firewall_private_ip
  destinations = concat(
    local.udr_destinations_region1,
    local.udr_destinations_region2
  )
}

module "hub2_udr_region1" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub2_prefix}fw"
  location               = local.hub2_location
  subnet_id              = module.hub2.subnets["AzureFirewallSubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.hub1.firewall_private_ip
  destinations = concat(
    local.udr_destinations_region1
  )
}

####################################################
# firewall rules (classic)
####################################################

# network

resource "azurerm_firewall_network_rule_collection" "hub2_azfw_net_rule" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}azfw-net-rule"
  azure_firewall_name = module.hub2.firewall.name
  priority            = 100
  action              = "Allow"
  rule {
    name                  = "any-to-any"
    source_addresses      = ["*"]
    destination_ports     = ["*"]
    destination_addresses = ["*"]
    protocols             = ["Any"]
  }
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
