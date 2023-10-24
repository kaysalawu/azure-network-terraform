
####################################################
# spoke4
####################################################

# vnet connections

resource "azurerm_virtual_hub_connection" "spoke4_vnet_conn" {
  name                      = "${local.vhub2_prefix}spoke4-vnet-conn"
  virtual_hub_id            = azurerm_virtual_hub.vhub2.id
  remote_virtual_network_id = module.spoke4.vnet.id

  routing {
    associated_route_table_id = azurerm_virtual_hub.vhub2.default_route_table_id
    propagated_route_table {
      labels = [
        "default",
      ]
      route_table_ids = [
        azurerm_virtual_hub.vhub2.default_route_table_id,
      ]
    }
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

# udr

module "spoke5_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.spoke5_prefix}main"
  location               = local.spoke5_location
  subnet_id              = module.spoke5.subnets["${local.spoke5_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_nva_ilb_addr
  destinations = concat(
    local.udr_destinations_region1,
    local.udr_destinations_region2
  )
}

####################################################
# hub2
####################################################

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
    ]

    BGP_SESSIONS            = []
    BGP_ADVERTISED_NETWORKS = []
  })
}

# nva

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

module "hub2_udr_vpngw" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub2_prefix}vpngw"
  location               = local.hub2_location
  subnet_id              = module.hub2.subnets["GatewaySubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_nva_ilb_addr
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
  next_hop_in_ip_address = local.hub2_nva_ilb_addr
  destinations = concat(
    local.udr_destinations_region1,
    local.udr_destinations_region2
  )
}

# lng

resource "azurerm_local_network_gateway" "hub2_vhub2_lng0" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}vhub2-lng0"
  location            = local.hub2_location
  gateway_address     = local.vhub2_vpngw_pip0
  address_space = [
    "${local.vhub2_vpngw_bgp1}/32",
    local.spoke1_address_space[0],
    local.spoke2_address_space[0],
    local.hub1_address_space[0],
  ]
  bgp_settings {
    asn                 = local.vhub2_bgp_asn
    bgp_peering_address = local.vhub2_vpngw_bgp0
  }
}

resource "azurerm_local_network_gateway" "hub2_vhub2_lng1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}vhub2-lng1"
  location            = local.hub2_location
  gateway_address     = local.vhub2_vpngw_pip1
  address_space = [
    "${local.vhub2_vpngw_bgp1}/32",
    local.spoke1_address_space[0],
    local.spoke2_address_space[0],
    local.hub1_address_space[0],
  ]
  bgp_settings {
    asn                 = local.vhub2_bgp_asn
    bgp_peering_address = local.vhub2_vpngw_bgp1
  }
}

# lng connection (traffic selectors)

resource "azurerm_virtual_network_gateway_connection" "hub2_vhub2_lng0" {
  resource_group_name                = azurerm_resource_group.rg.name
  name                               = "${local.hub2_prefix}vhub2-lng0"
  location                           = local.hub2_location
  type                               = "IPsec"
  enable_bgp                         = false
  virtual_network_gateway_id         = module.hub2.vpngw.id
  local_network_gateway_id           = azurerm_local_network_gateway.hub2_vhub2_lng0.id
  shared_key                         = local.psk
  use_policy_based_traffic_selectors = true
  traffic_selector_policy {
    local_address_cidrs = [
      local.spoke5_address_space[0],
    ]
    remote_address_cidrs = [
      local.spoke1_address_space[0],
      local.spoke2_address_space[0],
      local.hub1_address_space[0],
    ]
  }
}

resource "azurerm_virtual_network_gateway_connection" "hub2_vhub2_lng1" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub2_prefix}vhub2-lng1"
  location                   = local.hub2_location
  type                       = "IPsec"
  enable_bgp                 = false
  virtual_network_gateway_id = module.hub2.vpngw.id
  local_network_gateway_id   = azurerm_local_network_gateway.hub2_vhub2_lng1.id
  shared_key                 = local.psk
  traffic_selector_policy {
    local_address_cidrs = [
      local.spoke5_address_space[0],
    ]
    remote_address_cidrs = [
      local.spoke1_address_space[0],
      local.spoke2_address_space[0],
      local.hub1_address_space[0],
    ]
  }
}

/*
resource "azurerm_virtual_network_gateway_connection" "hub2_vhub2_lng0" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub2_prefix}vhub2-lng0"
  location                   = local.hub2_location
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = module.hub2.vpngw.id
  local_network_gateway_id   = azurerm_local_network_gateway.hub2_vhub2_lng0.id
  shared_key                 = local.psk
}

resource "azurerm_virtual_network_gateway_connection" "hub2_vhub2_lng1" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub2_prefix}vhub2-lng1"
  location                   = local.hub2_location
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = module.hub2.vpngw.id
  local_network_gateway_id   = azurerm_local_network_gateway.hub2_vhub2_lng1.id
  shared_key                 = local.psk
}*/

####################################################
# branch3
####################################################

# vpn-site connection

resource "azurerm_vpn_gateway_connection" "vhub2_site_branch3_conn" {
  name                      = "${local.vhub2_prefix}site-branch3-conn"
  vpn_gateway_id            = azurerm_vpn_gateway.vhub2.id
  remote_vpn_site_id        = azurerm_vpn_site.vhub2_site_branch3.id
  internet_security_enabled = false

  vpn_link {
    name             = "${local.vhub2_prefix}site-branch3-conn-vpn-link-0"
    bgp_enabled      = true
    shared_key       = local.psk
    vpn_site_link_id = azurerm_vpn_site.vhub2_site_branch3.link[0].id
  }

  routing {
    associated_route_table = azurerm_virtual_hub.vhub2.default_route_table_id
    propagated_route_table {
      labels = [
        "default",
      ]
      route_table_ids = [
        azurerm_virtual_hub.vhub2.default_route_table_id,
      ]
    }
  }
}

####################################################
# vhub2
####################################################

# vpn-site connection

resource "azurerm_vpn_gateway_connection" "vhub2_site_hub2_conn" {
  name                      = "${local.vhub2_prefix}site-hub2-conn"
  vpn_gateway_id            = azurerm_vpn_gateway.vhub2.id
  remote_vpn_site_id        = azurerm_vpn_site.vhub2_site_hub2.id
  internet_security_enabled = false

  traffic_selector_policy {
    local_address_ranges = [
      local.spoke1_address_space[0],
      local.spoke2_address_space[0],
      local.hub1_address_space[0],
      local.branch1_address_space[0],
    ]
    remote_address_ranges = [
      local.hub2_address_space[0],
      local.spoke5_address_space[0],
    ]
  }

  vpn_link {
    name             = "${local.vhub2_prefix}site-hub2-conn-vpn-link-0"
    bgp_enabled      = false
    shared_key       = local.psk
    vpn_site_link_id = azurerm_vpn_site.vhub2_site_hub2.link[0].id

    policy_based_traffic_selector_enabled = true
  }
  vpn_link {
    name             = "${local.vhub2_prefix}site-hub2-conn-vpn-link-1"
    bgp_enabled      = false
    shared_key       = local.psk
    vpn_site_link_id = azurerm_vpn_site.vhub2_site_hub2.link[1].id

    policy_based_traffic_selector_enabled = true
  }

  routing {
    associated_route_table = azurerm_virtual_hub.vhub2.default_route_table_id
    propagated_route_table {
      labels = [
        "default",
      ]
      route_table_ids = [
        azurerm_virtual_hub.vhub2.default_route_table_id,
      ]
    }
  }
}
