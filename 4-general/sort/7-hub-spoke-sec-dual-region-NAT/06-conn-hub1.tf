
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

# udr
#----------------------------

module "spoke1_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.spoke1_prefix}main"
  location               = local.spoke1_location
  subnet_id              = module.spoke1.subnets["${local.spoke1_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.hub1.firewall_private_ip
  destinations = concat(
    local.udr_destinations_region1,
    local.udr_destinations_region2
  )
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

# udr
#----------------------------

module "spoke2_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.spoke2_prefix}main"
  location               = local.spoke2_location
  subnet_id              = module.spoke2.subnets["${local.spoke2_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.hub1.firewall_private_ip
  destinations = concat(
    local.udr_destinations_region1,
    local.udr_destinations_region2
  )
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

# nat
#----------------------------

data "azurerm_virtual_network_gateway" "hub1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = module.hub1.vpngw.name
}

# egress (static)

resource "azurerm_virtual_network_gateway_nat_rule" "hub1_branch1_static_nat_egress" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub1_prefix}branch1-static-nat-egress"
  virtual_network_gateway_id = module.hub1.vpngw.id
  mode                       = "EgressSnat"
  type                       = "Static"

  internal_mapping {
    address_space = local.spoke1_subnets["${local.spoke1_prefix}main"].address_prefixes[0]
  }
  external_mapping {
    address_space = local.hub1_nat_ranges["branch1"]["egress-static"]
  }
}

# egress (dynamic)

resource "azurerm_virtual_network_gateway_nat_rule" "hub1_branch1_dyn_nat_egress_0" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub1_prefix}branch1-dyn-nat-egress-0"
  virtual_network_gateway_id = module.hub1.vpngw.id
  mode                       = "EgressSnat"
  type                       = "Dynamic"
  ip_configuration_id        = data.azurerm_virtual_network_gateway.hub1.ip_configuration.0.id

  internal_mapping {
    address_space = local.spoke1_subnets["${local.spoke1_prefix}main"].address_prefixes[0]
  }
  external_mapping {
    address_space = cidrsubnet(local.hub1_nat_ranges["branch1"]["egress-dynamic"], 2, 0)
  }
}

resource "azurerm_virtual_network_gateway_nat_rule" "hub1_branch1_dyn_nat_egress_1" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub1_prefix}branch1-dyn-nat-egress-1"
  virtual_network_gateway_id = module.hub1.vpngw.id
  mode                       = "EgressSnat"
  type                       = "Dynamic"
  ip_configuration_id        = data.azurerm_virtual_network_gateway.hub1.ip_configuration.1.id

  internal_mapping {
    address_space = local.spoke1_subnets["${local.spoke1_prefix}main"].address_prefixes[0]
  }
  external_mapping {
    address_space = cidrsubnet(local.hub1_nat_ranges["branch1"]["egress-dynamic"], 2, 1)
  }
}

# ingress (static)

resource "azurerm_virtual_network_gateway_nat_rule" "hub1_branch1_static_nat_ingress" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub1_prefix}branch1-static-nat-ingress"
  virtual_network_gateway_id = module.hub1.vpngw.id
  mode                       = "IngressSnat"
  type                       = "Static"

  internal_mapping {
    address_space = local.branch1_subnets["${local.branch1_prefix}main"].address_prefixes[0]
  }
  external_mapping {
    address_space = local.hub1_nat_ranges["branch1"]["ingress-static"]
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
  egress_nat_rule_ids = [
    azurerm_virtual_network_gateway_nat_rule.hub1_branch1_static_nat_egress.id,
    #azurerm_virtual_network_gateway_nat_rule.hub1_branch1_dyn_nat_egress_0.id,
    #azurerm_virtual_network_gateway_nat_rule.hub1_branch1_dyn_nat_egress_1.id,
  ]
  ingress_nat_rule_ids = [
    azurerm_virtual_network_gateway_nat_rule.hub1_branch1_static_nat_ingress.id,
  ]
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
      { network = local.hub2_nva_loopback0, mask = "255.255.255.255", next_hop = "Tunnel0" },
      { network = local.hub2_nva_addr, mask = "255.255.255.255", next_hop = local.hub1_default_gw_nva },
      {
        network  = split("/", local.branch3_address_space[0])[0]
        mask     = cidrnetmask(local.branch3_address_space[0])
        next_hop = local.hub1_default_gw_nva
      },
      {
        network  = split("/", local.hub2_address_space[0])[0]
        mask     = cidrnetmask(local.hub2_address_space[0])
        next_hop = local.hub1_default_gw_nva
      },
      {
        network  = split("/", local.spoke4_address_space[0])[0]
        mask     = cidrnetmask(local.spoke4_address_space[0])
        next_hop = local.hub1_default_gw_nva
      },
      {
        network  = split("/", local.spoke5_address_space[0])[0]
        mask     = cidrnetmask(local.spoke5_address_space[0])
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
      { network = split("/", local.branch3_address_space[0])[0], mask = cidrnetmask(local.branch3_address_space[0]) },
      { network = split("/", local.hub2_address_space[0])[0], mask = cidrnetmask(local.hub2_address_space[0]) },
      { network = split("/", local.spoke4_address_space[0])[0], mask = cidrnetmask(local.spoke4_address_space[0]) },
      { network = split("/", local.spoke5_address_space[0])[0], mask = cidrnetmask(local.spoke5_address_space[0]) }
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

# udr
#----------------------------

module "hub1_udr_gateway" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub1_prefix}gateway"
  location               = local.hub1_location
  subnet_id              = module.hub1.subnets["GatewaySubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.hub1.firewall_private_ip
  destinations = concat(
    local.udr_destinations_region1,
    local.udr_destinations_region2
  )
}

module "hub1_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub1_prefix}main"
  location               = local.hub1_location
  subnet_id              = module.hub1.subnets["${local.hub1_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.hub1.firewall_private_ip
  destinations = concat(
    local.udr_destinations_region1,
    local.udr_destinations_region2
  )
}

module "hub1_udr_region2" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub1_prefix}fw"
  location               = local.hub1_location
  subnet_id              = module.hub1.subnets["AzureFirewallSubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.hub2.firewall_private_ip
  destinations = concat(
    local.udr_destinations_region2
  )
}

####################################################
# firewall rules (classic)
####################################################

# network

resource "azurerm_firewall_network_rule_collection" "hub1_azfw_net_rule" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}azfw-net-rule"
  azure_firewall_name = module.hub1.firewall.name
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
