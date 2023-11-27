
####################################################
# spoke4
####################################################

# vnet peering
#----------------------------

# spoke4-to-hub2

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

# main

module "spoke4_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.spoke4_prefix}main"
  location               = local.spoke4_location
  subnet_id              = module.spoke4.subnets["MainSubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_nva_ilb_addr

  destinations = merge(
    local.default_udr_destinations,
    { "hub2" = local.hub2_address_space[0] }
  )
  depends_on = [module.hub2, ]

  disable_bgp_route_propagation = true
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

# main

module "spoke5_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.spoke5_prefix}main"
  location               = local.spoke5_location
  subnet_id              = module.spoke5.subnets["MainSubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_nva_ilb_addr

  destinations = merge(
    local.default_udr_destinations,
    { "hub2" = local.hub2_address_space[0] }
  )
  depends_on = [module.hub2, ]

  disable_bgp_route_propagation = true
}

####################################################
# hub2
####################################################

# nva
#----------------------------

locals {
  hub2_cisco_nva_route_map_name_nh = "NEXT-HOP"
  hub2_cisco_nva_init = templatefile("../../scripts/cisco-hub.sh", {
    LOCAL_ASN = local.hub2_nva_asn
    LOOPBACK0 = local.hub2_nva_loopback0
    LOOPBACKS = {
      Loopback1 = local.hub2_nva_ilb_addr
    }
    CRYPTO_ADDR = local.hub2_nva_trust_addr
    VPN_PSK     = local.psk

    ROUTE_MAPS = [
      {
        name   = local.hub2_cisco_nva_route_map_name_nh
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
          source  = local.hub2_nva_trust_addr
          dest    = local.hub1_nva_trust_addr
        },
        ipsec = {
          peer_ip = local.hub1_nva_trust_addr
          psk     = local.psk
        }
      },
    ]

    STATIC_ROUTES = [
      { network = "0.0.0.0", mask = "0.0.0.0", next_hop = local.hub2_default_gw_nva },
      { network = local.hub1_nva_loopback0, mask = "255.255.255.255", next_hop = "Tunnel0" },
      { network = local.hub1_nva_trust_addr, mask = "255.255.255.255", next_hop = local.hub2_default_gw_nva },
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
          name      = local.hub2_cisco_nva_route_map_name_nh
          direction = "out"
        }
      },
      {
        peer_asn      = local.hub2_ars_bgp_asn
        peer_ip       = local.hub2_ars_bgp1
        as_override   = true
        ebgp_multihop = true
        route_map = {
          name      = local.hub2_cisco_nva_route_map_name_nh
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

# nva

module "hub2_nva" {
  source               = "../../modules/csr-hub"
  resource_group       = azurerm_resource_group.rg.name
  name                 = "${local.hub2_prefix}nva"
  location             = local.hub2_location
  subnet               = module.hub2.subnets["${local.hub2_prefix}nva"].id
  private_ip           = local.hub2_nva_trust_addr
  enable_ip_forwarding = true
  enable_public_ip     = true
  storage_account      = module.common.storage_accounts["region2"]
  admin_username       = local.username
  admin_password       = local.password
  custom_data          = base64encode(local.hub2_cisco_nva_init)
}

# udr
#----------------------------

# gateway

module "hub2_udr_gateway" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub2_prefix}gateway"
  location               = local.hub2_location
  subnet_id              = module.hub2.subnets["GatewaySubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_nva_ilb_addr
  destinations           = local.hub2_gateway_udr_destinations
  depends_on             = [module.hub2, ]
}

# main

module "hub2_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub2_prefix}main"
  location               = local.hub2_location
  subnet_id              = module.hub2.subnets["MainSubnet"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_nva_ilb_addr

  destinations = merge(
    local.default_udr_destinations,
    { "hub2" = local.hub2_address_space[0] }
  )
  depends_on = [module.hub2, ]

  disable_bgp_route_propagation = true
}

####################################################
# internal lb
####################################################

resource "azurerm_lb" "hub2_nva_lb" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}nva-lb"
  location            = local.hub2_location
  sku                 = "Standard"
  frontend_ip_configuration {
    name                          = "${local.hub2_prefix}nva-lb-feip"
    subnet_id                     = module.hub2.subnets["${local.hub2_prefix}ilb"].id
    private_ip_address            = local.hub2_nva_ilb_addr
    private_ip_address_allocation = "Static"
  }
  lifecycle {
    ignore_changes = [frontend_ip_configuration, ]
  }
}

# backend

resource "azurerm_lb_backend_address_pool" "hub2_nva" {
  name            = "${local.hub2_prefix}nva-beap"
  loadbalancer_id = azurerm_lb.hub2_nva_lb.id
}

resource "azurerm_lb_backend_address_pool_address" "hub2_nva" {
  name                    = "${local.hub2_prefix}nva-beap-addr"
  backend_address_pool_id = azurerm_lb_backend_address_pool.hub2_nva.id
  virtual_network_id      = module.hub2.vnet.id
  ip_address              = local.hub2_nva_trust_addr
}

# probe

resource "azurerm_lb_probe" "hub2_nva_lb_probe" {
  name                = "${local.hub2_prefix}nva-probe"
  interval_in_seconds = 5
  number_of_probes    = 2
  loadbalancer_id     = azurerm_lb.hub2_nva_lb.id
  port                = 22
  protocol            = "Tcp"
}

# rule

resource "azurerm_lb_rule" "hub2_nva" {
  name     = "${local.hub2_prefix}nva-rule"
  protocol = "All"
  backend_address_pool_ids = [
    azurerm_lb_backend_address_pool.hub2_nva.id
  ]
  loadbalancer_id                = azurerm_lb.hub2_nva_lb.id
  frontend_port                  = 0
  backend_port                   = 0
  frontend_ip_configuration_name = "${local.hub2_prefix}nva-lb-feip"
  enable_floating_ip             = false
  idle_timeout_in_minutes        = 30
  load_distribution              = "Default"
  probe_id                       = azurerm_lb_probe.hub2_nva_lb_probe.id
}

####################################################
# vpn-site connection
####################################################

# lng
#----------------------------

# branch3

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

# branch3

resource "azurerm_virtual_network_gateway_connection" "hub2_branch3_lng" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub2_prefix}branch3-lng-conn"
  location                   = local.hub2_location
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = module.hub2.vpngw.id
  local_network_gateway_id   = azurerm_local_network_gateway.hub2_branch3_lng.id
  shared_key                 = local.psk
  egress_nat_rule_ids        = []
  ingress_nat_rule_ids       = []
}

####################################################
# bgp connections
####################################################

# hub2

resource "azurerm_route_server_bgp_connection" "hub2_ars_bgp_conn" {
  name            = "${local.hub2_prefix}ars-bgp-conn"
  route_server_id = module.hub2.ars.id
  peer_asn        = local.hub2_nva_asn
  peer_ip         = local.hub2_nva_trust_addr
}

####################################################
# output files
####################################################

locals {
  hub2_files = {
    "output/hub2-cisco-nva.sh" = local.hub2_cisco_nva_init
  }
}

resource "local_file" "hub2_files" {
  for_each = local.hub2_files
  filename = each.key
  content  = each.value
}

