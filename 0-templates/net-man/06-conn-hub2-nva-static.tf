locals {
  hub2_bgp_asn       = module.hub2.vpngw.bgp_settings[0].asn
  hub2_vpngw_bgp_ip0 = module.hub2.vpngw.bgp_settings[0].peering_addresses[0].default_addresses[0]
  hub2_vpngw_bgp_ip1 = module.hub2.vpngw.bgp_settings[0].peering_addresses[1].default_addresses[0]
}

####################################################
# spoke4
####################################################

# udr
#----------------------------

module "spoke4_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.spoke4_prefix}main"
  location               = local.spoke4_location
  subnet_id              = module.spoke4.subnets["${local.spoke4_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_nva_ilb_addr
  destinations           = local.main_udr_destinations
  depends_on             = [module.hub2]
}

####################################################
# spoke5
####################################################

# udr
#----------------------------

module "spoke5_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.spoke5_prefix}main"
  location               = local.spoke5_location
  subnet_id              = module.spoke5.subnets["${local.spoke5_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_nva_ilb_addr
  destinations           = local.main_udr_destinations
  depends_on             = [module.hub2]
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
    INT_ADDR = local.hub2_nva_addr
    VPN_PSK  = local.psk

    MASQUERADE = []

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
  storage_account      = module.common.storage_accounts["region2"]
  admin_username       = local.username
  admin_password       = local.password
  custom_data          = base64encode(local.hub2_cisco_nva_init)
}

# udr

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

module "hub2_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub2_prefix}main"
  location               = local.hub2_location
  subnet_id              = module.hub2.subnets["${local.hub2_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_nva_ilb_addr
  destinations           = local.main_udr_destinations
  depends_on             = [module.hub2, ]
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
  ip_address              = local.hub2_nva_addr
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

# branch1

resource "azurerm_local_network_gateway" "hub2_branch1_lng" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.hub2_prefix}branch1-lng"
  location            = local.hub2_location
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

resource "azurerm_virtual_network_gateway_connection" "hub2_branch1_lng" {
  resource_group_name        = azurerm_resource_group.rg.name
  name                       = "${local.hub2_prefix}branch1-lng-conn"
  location                   = local.hub2_location
  type                       = "IPsec"
  enable_bgp                 = true
  virtual_network_gateway_id = module.hub2.vpngw.id
  local_network_gateway_id   = azurerm_local_network_gateway.hub2_branch1_lng.id
  shared_key                 = local.psk
  egress_nat_rule_ids        = []
  ingress_nat_rule_ids       = []
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

