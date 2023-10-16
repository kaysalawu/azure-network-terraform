locals {
  hub1_vpngw_bgp_asn = module.hub1.vpngw.bgp_settings[0].asn
  hub1_vpngw_bgp_ip0 = module.hub1.vpngw.bgp_settings[0].peering_addresses[0].default_addresses[0]
  hub1_vpngw_bgp_ip1 = module.hub1.vpngw.bgp_settings[0].peering_addresses[1].default_addresses[0]
  hub1_ars_bgp0      = tolist(module.hub1.ars.virtual_router_ips)[0]
  hub1_ars_bgp1      = tolist(module.hub1.ars.virtual_router_ips)[1]
  hub1_ars_bgp_asn   = module.hub1.ars.virtual_router_asn
}

####################################################
# spoke1
####################################################

# vnet peering
#----------------------------

# spoke1-to-hub1

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

# main

module "spoke1_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.spoke1_prefix}main"
  location               = local.spoke1_location
  subnet_id              = module.spoke1.subnets["${local.spoke1_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub1_nva_ilb_addr

  destinations = merge(
    local.default_udr_destinations,
    { "hub1" = local.hub1_address_space[0] }
  )
  depends_on = [module.hub1, ]

  disable_bgp_route_propagation = true
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

# main

module "spoke2_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.spoke2_prefix}main"
  location               = local.spoke2_location
  subnet_id              = module.spoke2.subnets["${local.spoke2_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub1_nva_ilb_addr

  destinations = merge(
    local.default_udr_destinations,
    { "hub1" = local.hub1_address_space[0] }
  )
  depends_on = [module.hub1]

  disable_bgp_route_propagation = true
}

####################################################
# hub1
####################################################

# nva
#----------------------------

locals {
  hub1_cisco_nva_route_map_name_nh = "NEXT-HOP"
  hub1_cisco_nva_init = templatefile("../../scripts/cisco-hub.sh", {
    LOCAL_ASN = local.hub1_nva_asn
    LOOPBACK0 = local.hub1_nva_loopback0
    LOOPBACKS = {
      Loopback1 = local.hub1_nva_ilb_addr
    }
    INT_ADDR = local.hub1_nva_addr
    VPN_PSK  = local.psk

    ROUTE_MAPS = [
      {
        name   = local.hub1_cisco_nva_route_map_name_nh
        action = "permit"
        rule   = 100
        commands = [
          "match ip address prefix-list all",
          "set ip next-hop ${local.hub1_nva_ilb_addr}"
        ]
      }
    ]

    TUNNELS = [
      {
        ike = {
          name    = "Tunnel0"
          address = cidrhost(local.hub1_nva_tun_range0, 1)
          mask    = cidrnetmask(local.hub1_nva_tun_range0)
          source  = local.hub1_nva_addr
          dest    = local.hub2_nva_addr
        },
        ipsec = {
          peer_ip = local.hub2_nva_addr
          psk     = local.psk
        }
      },
    ]

    STATIC_ROUTES = [
      { network = "0.0.0.0", mask = "0.0.0.0", next_hop = local.hub1_default_gw_nva },
      { network = local.hub2_nva_loopback0, mask = "255.255.255.255", next_hop = "Tunnel0" },
      { network = local.hub2_nva_addr, mask = "255.255.255.255", next_hop = local.hub1_default_gw_nva },
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
          name      = local.hub1_cisco_nva_route_map_name_nh
          direction = "out"
        }
      },
      {
        peer_asn      = local.hub1_ars_bgp_asn
        peer_ip       = local.hub1_ars_bgp1
        as_override   = true
        ebgp_multihop = true
        route_map = {
          name      = local.hub1_cisco_nva_route_map_name_nh
          direction = "out"
        }
      },
      {
        peer_asn        = local.hub2_nva_asn
        peer_ip         = local.hub2_nva_loopback0
        next_hop_self   = true
        source_loopback = true
        route_map       = {}
      },
    ]

    BGP_ADVERTISED_NETWORKS = []
  })
}

# nva

module "hub1_nva" {
  source               = "../../modules/csr-hub"
  resource_group       = azurerm_resource_group.rg.name
  name                 = "${local.hub1_prefix}nva"
  location             = local.hub1_location
  subnet               = module.hub1.subnets["${local.hub1_prefix}nva"].id
  private_ip           = local.hub1_nva_addr
  enable_ip_forwarding = true
  enable_public_ip     = true
  storage_account      = module.common.storage_accounts["region1"]
  admin_username       = local.username
  admin_password       = local.password
  custom_data          = base64encode(local.hub1_cisco_nva_init)
}

# udr
#----------------------------

# gateway

module "hub1_udr_gateway" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub1_prefix}gateway"
  location               = local.hub1_location
  subnet_id              = module.hub1.subnets["GatewaySubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub1_nva_ilb_addr
  destinations           = local.hub1_gateway_udr_destinations
  depends_on             = [module.hub1, ]
}

# main

module "hub1_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub1_prefix}main"
  location               = local.hub1_location
  subnet_id              = module.hub1.subnets["${local.hub1_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub1_nva_ilb_addr

  destinations = merge(
    local.default_udr_destinations,
    { "hub1" = local.hub1_address_space[0] }
  )
  depends_on = [module.hub1, ]

  disable_bgp_route_propagation = true
}

####################################################
# internal lb
####################################################

resource "azurerm_lb" "hub1_nva_lb" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub1_prefix}nva-lb"
  location            = local.hub1_location
  sku                 = "Standard"
  frontend_ip_configuration {
    name                          = "${local.hub1_prefix}nva-lb-feip"
    subnet_id                     = module.hub1.subnets["${local.hub1_prefix}ilb"].id
    private_ip_address            = local.hub1_nva_ilb_addr
    private_ip_address_allocation = "Static"
  }
  lifecycle {
    ignore_changes = [frontend_ip_configuration, ]
  }
}

# backend

resource "azurerm_lb_backend_address_pool" "hub1_nva" {
  name            = "${local.hub1_prefix}nva-beap"
  loadbalancer_id = azurerm_lb.hub1_nva_lb.id
}

resource "azurerm_lb_backend_address_pool_address" "hub1_nva" {
  name                    = "${local.hub1_prefix}nva-beap-addr"
  backend_address_pool_id = azurerm_lb_backend_address_pool.hub1_nva.id
  virtual_network_id      = module.hub1.vnet.id
  ip_address              = local.hub1_nva_addr
}

# probe

resource "azurerm_lb_probe" "hub1_nva_lb_probe" {
  name                = "${local.hub1_prefix}nva-probe"
  interval_in_seconds = 5
  number_of_probes    = 2
  loadbalancer_id     = azurerm_lb.hub1_nva_lb.id
  port                = 22
  protocol            = "Tcp"
}

# rule

resource "azurerm_lb_rule" "hub1_nva" {
  name     = "${local.hub1_prefix}nva-rule"
  protocol = "All"
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.hub1_nva.id
  ]
  loadbalancer_id                = azurerm_lb.hub1_nva_lb.id
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "${local.hub1_prefix}nva-lb-feip"
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 30
  load_distribution              = "Default"
  probe_id                       = azurerm_lb_probe.hub1_nva_lb_probe.id
}

####################################################
# vpn-site connection
####################################################

# lng
#----------------------------

# branch1

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

# branch1

resource "azurerm_virtual_network_gateway_connection" "hub1_branch1_lng" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub1_prefix}branch1-lng-conn"
  location                   = local.hub1_location
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = module.hub1.vpngw.id
  local_network_gateway_id   = azurerm_local_network_gateway.hub1_branch1_lng.id
  shared_key                 = local.psk
  egress_nat_rule_ids        = []
  ingress_nat_rule_ids       = []
}

####################################################
# bgp connections
####################################################

# hub1

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
    "output/hub1-cisco-nva.sh" = local.hub1_cisco_nva_init
  }
}

resource "local_file" "hub1_files" {
  for_each = local.hub1_files
  filename = each.key
  content  = each.value
}

