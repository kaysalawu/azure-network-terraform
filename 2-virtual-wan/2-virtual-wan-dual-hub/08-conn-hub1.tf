
####################################################
# vnet peering
####################################################

# spoke2-to-hub1

resource "azurerm_virtual_network_peering" "spoke2_to_hub1_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-spoke2-to-hub1-peering"
  virtual_network_name         = module.spoke2.vnet.name
  remote_virtual_network_id    = module.hub1.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  #use_remote_gateways          = true
}

# hub1-to-spoke2

resource "azurerm_virtual_network_peering" "hub1_to_spoke2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub1-to-spoke2-peering"
  virtual_network_name         = module.hub1.vnet.name
  remote_virtual_network_id    = module.spoke2.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  #allow_gateway_transit        = true
}

####################################################
# nva
####################################################

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
      { network = local.vhub1_router_bgp0, mask = "255.255.255.255", next_hop = local.hub1_default_gw_nva },
      { network = local.vhub1_router_bgp1, mask = "255.255.255.255", next_hop = local.hub1_default_gw_nva },
      {
        network  = cidrhost(local.spoke2_address_space[0], 0),
        mask     = cidrnetmask(local.spoke2_address_space[0])
        next_hop = local.hub1_default_gw_nva
      },
    ]

    BGP_SESSIONS = [
      {
        peer_asn      = local.vhub1_bgp_asn
        peer_ip       = local.vhub1_router_bgp0
        ebgp_multihop = true
        route_map = {
          #name      = local.hub1_router_route_map_name_nh
          #direction = "out"
        }
      },
      {
        peer_asn      = local.vhub1_bgp_asn
        peer_ip       = local.vhub1_router_bgp1
        ebgp_multihop = true
        route_map = {
          #name      = local.hub1_router_route_map_name_nh
          #direction = "out"
        }
      },
    ]
    BGP_ADVERTISED_NETWORKS = [
      {
        network = cidrhost(local.spoke2_address_space[0], 0)
        mask    = cidrnetmask(local.spoke2_address_space[0])
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
# udr
####################################################

# spoke2
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
    spoke2 = "10.0.0.0/8"
  }
}

resource "azurerm_route" "spoke2_routes_hub1" {
  for_each               = local.rt_spoke2_routes
  name                   = "${local.prefix}-${each.key}-route-hub1"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.rt_spoke2.name
  address_prefix         = each.value
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub1_nva_addr
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
# vpn-site connection
####################################################

# branch1

resource "azurerm_vpn_gateway_connection" "vhub1_site_branch1_conn" {
  name                      = "${local.vhub1_prefix}site-branch1-conn"
  vpn_gateway_id            = azurerm_vpn_gateway.vhub1.id
  remote_vpn_site_id        = azurerm_vpn_site.vhub1_site_branch1.id
  internet_security_enabled = false

  vpn_link {
    name             = "${local.vhub1_prefix}site-branch1-conn-vpn-link-0"
    bgp_enabled      = true
    shared_key       = local.psk
    vpn_site_link_id = azurerm_vpn_site.vhub1_site_branch1.link[0].id
  }

  routing {
    associated_route_table = azurerm_virtual_hub.vhub1.default_route_table_id
    propagated_route_table {
      labels = [
        "default",
        "blue",
        "red"
      ]
      route_table_ids = [
        #azurerm_virtual_hub.vhub1.default_route_table_id,
        #azurerm_virtual_hub_route_table.vhub1_rt_blue.id,
        #azurerm_virtual_hub_route_table.vhub1_rt_red.id,
      ]
    }
  }
}

####################################################
# vnet connections
####################################################

# spoke1
#----------------------------

resource "azurerm_virtual_hub_connection" "spoke1_vnet_conn" {
  name                      = "${local.vhub1_prefix}spoke1-vnet-conn"
  virtual_hub_id            = azurerm_virtual_hub.vhub1.id
  remote_virtual_network_id = module.spoke1.vnet.id

  routing {
    associated_route_table_id = azurerm_virtual_hub_route_table.vhub1_rt_blue.id
    propagated_route_table {
      labels = [
        "default",
        "blue",
        "red",
      ]
      route_table_ids = [
        #azurerm_virtual_hub.vhub1.default_route_table_id,
        #azurerm_virtual_hub_route_table.vhub1_rt_blue.id,
        #azurerm_virtual_hub_route_table.vhub1_rt_red.id,
      ]
    }
  }
}

# hub1
#----------------------------

locals {
  vhub1_hub1_vnet_conn_routes = [
    /*{
      name                = "spoke2"
      address_prefixes    = local.spoke3_address_space
      next_hop_ip_address = local.hub1_nva_ilb_addr
    },*/
  ]
}


resource "azurerm_virtual_hub_connection" "hub1_vnet_conn" {
  name                      = "${local.vhub1_prefix}hub1-vnet-conn"
  virtual_hub_id            = azurerm_virtual_hub.vhub1.id
  remote_virtual_network_id = module.hub1.vnet.id

  routing {
    associated_route_table_id = azurerm_virtual_hub.vhub1.default_route_table_id
    propagated_route_table {
      labels = [
        "default",
        "blue",
        "red",
      ]
      route_table_ids = [
        #azurerm_virtual_hub.vhub1.default_route_table_id,
        #azurerm_virtual_hub_route_table.vhub1_rt_blue.id,
        #azurerm_virtual_hub_route_table.vhub1_rt_red.id,
      ]
    }
    dynamic "static_vnet_route" {
      for_each = local.vhub1_hub1_vnet_conn_routes
      content {
        name                = static_vnet_route.value.name
        address_prefixes    = static_vnet_route.value.address_prefixes
        next_hop_ip_address = static_vnet_route.value.next_hop_ip_address
      }
    }
  }
}

####################################################
# bgp connections
####################################################

# hub1

resource "azurerm_virtual_hub_bgp_connection" "vhub1_hub1_bgp_conn" {
  name           = "${local.vhub1_prefix}hub1-bgp-conn"
  virtual_hub_id = azurerm_virtual_hub.vhub1.id
  peer_asn       = local.hub1_nva_asn
  peer_ip        = local.hub1_nva_addr

  virtual_network_connection_id = azurerm_virtual_hub_connection.hub1_vnet_conn.id
}

####################################################
# static routes
####################################################

locals {
  vhub1_routes = [
    # static routes used by all RTs to reach spoke3
    {
      name           = "${local.vhub1_prefix}rt-red-spoke3"
      destinations   = local.spoke3_address_space
      route_table_id = azurerm_virtual_hub_route_table.vhub1_rt_red.id
      next_hop       = azurerm_virtual_hub_connection.hub1_vnet_conn.id
    },
    {
      name           = "${local.vhub1_prefix}rt-blue-spoke3"
      destinations   = local.spoke3_address_space
      route_table_id = azurerm_virtual_hub_route_table.vhub1_rt_blue.id
      next_hop       = azurerm_virtual_hub_connection.hub1_vnet_conn.id
    },
    {
      name           = "${local.vhub1_prefix}rt-default-spoke3"
      destinations   = local.spoke3_address_space
      route_table_id = azurerm_virtual_hub.vhub1.default_route_table_id
      next_hop       = azurerm_virtual_hub_connection.hub1_vnet_conn.id
    },
  ]
}

/*resource "azurerm_virtual_hub_route_table_route" "vhub1_routes" {
  for_each          = { for k, v in local.vhub1_routes : k => v }
  name              = each.value.name
  route_table_id    = each.value.route_table_id
  destinations_type = "CIDR"
  destinations      = each.value.destinations
  next_hop_type     = "ResourceId"
  next_hop          = each.value.next_hop
}*/
