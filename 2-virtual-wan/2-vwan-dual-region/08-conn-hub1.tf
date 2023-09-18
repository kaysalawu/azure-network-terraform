
locals {
  vhub1_router_bgp_ip0   = module.vhub1.router_bgp_ip0
  vhub1_router_bgp_ip1   = module.vhub1.router_bgp_ip1
  vhub1_vpngw_public_ip0 = module.vhub1.vpn_gateway_public_ip0
  vhub1_vpngw_public_ip1 = module.vhub1.vpn_gateway_public_ip1
  vhub1_vpngw_bgp_ip0    = module.vhub1.vpn_gateway_bgp_ip0
  vhub1_vpngw_bgp_ip1    = module.vhub1.vpn_gateway_bgp_ip1
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
  use_remote_gateways          = false
}

# hub1-to-spoke2

resource "azurerm_virtual_network_peering" "hub1_to_spoke2_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub1-to-spoke2-peering"
  virtual_network_name         = module.hub1.vnet.name
  remote_virtual_network_id    = module.spoke2.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
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
  next_hop_in_ip_address = local.hub1_nva_ilb_addr
  destinations = concat(
    ["0.0.0.0/0"],
    local.main_udr_destinations
  )
  depends_on = [module.hub1]
}

####################################################
# hub1
####################################################

# nva
#----------------------------

locals {
  hub1_router_route_map_name_nh = "NEXT-HOP"
  hub1_nva_vars = {
    LOCAL_ASN = local.hub1_nva_asn
    LOOPBACK0 = local.hub1_nva_loopback0
    LOOPBACKS = {
      Loopback1 = local.hub1_nva_ilb_addr
    }
    INT_ADDR = local.hub1_nva_addr
    VPN_PSK  = local.psk
  }
  hub1_linux_nva_init = templatefile("../../scripts/linux-nva.sh", merge(local.hub1_nva_vars, {
    TARGETS        = local.vm_script_targets_region1
    IPTABLES_RULES = []
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
    QUAGGA_ZEBRA_CONF = templatefile("../../scripts/quagga/zebra.conf", merge(
      local.hub1_nva_vars,
      {
        INTERFACE = "eth0"
        STATIC_ROUTES = [
          { prefix = "0.0.0.0/0", next_hop = local.hub1_default_gw_nva },
          { prefix = "${local.vhub1_router_bgp_ip0}/32", next_hop = local.hub1_default_gw_nva },
          { prefix = "${local.vhub1_router_bgp_ip1}/32", next_hop = local.hub1_default_gw_nva },
          { prefix = local.spoke2_address_space[0], next_hop = local.hub1_default_gw_nva },
        ]
      }
    ))
    QUAGGA_BGPD_CONF = templatefile("../../scripts/quagga/bgpd.conf", merge(
      local.hub1_nva_vars,
      {
        BGP_SESSIONS = [
          {
            peer_asn      = local.vhub1_bgp_asn
            peer_ip       = local.vhub1_router_bgp_ip0
            ebgp_multihop = true
            route_map = {
              #name      = local.hub1_router_route_map_name_nh
              #direction = "out"
            }
          },
          {
            peer_asn      = local.vhub1_bgp_asn
            peer_ip       = local.vhub1_router_bgp_ip1
            ebgp_multihop = true
            route_map = {
              #name      = local.hub1_router_route_map_name_nh
              #direction = "out"
            }
          },
        ]
        BGP_ADVERTISED_PREFIXES = [
          local.hub1_subnets["${local.hub1_prefix}main"].address_prefixes[0],
          local.spoke2_address_space[0],
          #"${local.spoke3_vm_public_ip}/32"
        ]
      }
    ))
    }
  ))
}

module "hub1_nva" {
  source               = "../../modules/linux"
  resource_group       = azurerm_resource_group.rg.name
  prefix               = ""
  name                 = "${local.hub1_prefix}nva"
  location             = local.hub1_location
  subnet               = module.hub1.subnets["${local.hub1_prefix}nva"].id
  private_ip           = local.hub1_nva_addr
  enable_ip_forwarding = true
  enable_public_ip     = true
  source_image         = "ubuntu"
  storage_account      = module.common.storage_accounts["region1"]
  admin_username       = local.username
  admin_password       = local.password
  custom_data          = base64encode(local.hub1_linux_nva_init)
}

# udr

module "hub1_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub1_prefix}main"
  location               = local.hub1_location
  subnet_id              = module.hub1.subnets["${local.hub1_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub1_nva_ilb_addr
  destinations           = local.main_udr_destinations
  depends_on             = [module.hub1]
}
/*
module "hub1_udr_nva" {
  source         = "../../modules/udr"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.hub1_prefix}nva"
  location       = local.hub1_location
  subnet_id      = module.hub1.subnets["${local.hub1_prefix}nva"].id
  next_hop_type  = "Internet"
  destinations   = ["${local.spoke3_vm_public_ip}/32", ]
  depends_on     = [module.hub1]
}*/

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

# sites
#----------------------------

# branch1

resource "azurerm_vpn_site" "vhub1_site_branch1" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.vhub1_prefix}site-branch1"
  location            = azurerm_virtual_wan.vwan.location
  virtual_wan_id      = azurerm_virtual_wan.vwan.id
  device_model        = "Azure"
  device_vendor       = "Microsoft"
  link {
    name          = "${local.vhub1_prefix}site-branch1-link-0"
    provider_name = "Microsoft"
    ip_address    = azurerm_public_ip.branch1_nva_pip.ip_address
    speed_in_mbps = 50
    bgp {
      asn             = local.branch1_nva_asn
      peering_address = local.branch1_nva_loopback0
    }
  }
}

resource "azurerm_vpn_gateway_connection" "vhub1_site_branch1_conn" {
  name                      = "${local.vhub1_prefix}site-branch1-conn"
  vpn_gateway_id            = module.vhub1.vpn_gateway.id
  remote_vpn_site_id        = azurerm_vpn_site.vhub1_site_branch1.id
  internet_security_enabled = true

  vpn_link {
    name             = "${local.vhub1_prefix}site-branch1-conn-vpn-link-0"
    bgp_enabled      = true
    shared_key       = local.psk
    vpn_site_link_id = azurerm_vpn_site.vhub1_site_branch1.link[0].id
  }

  # only enable routing if routing intent is not used
  dynamic "routing" {
    for_each = local.vhub1_features.security.use_routing_intent ? [] : [1]
    content {
      associated_route_table = module.vhub1.virtual_hub.default_route_table_id
      propagated_route_table {
        labels = [
          "default",
        ]
        route_table_ids = [
          module.vhub1.virtual_hub.default_route_table_id,
        ]
      }
    }
  }
}

####################################################
# vnet connections
####################################################

locals {
  vhub1_spoke1_vnet_conn_routes = []
}

# spoke1

resource "azurerm_virtual_hub_connection" "spoke1_vnet_conn" {
  name                      = "${local.vhub1_prefix}spoke1-vnet-conn"
  virtual_hub_id            = module.vhub1.virtual_hub.id
  remote_virtual_network_id = module.spoke1.vnet.id
  internet_security_enabled = true

  # only enable routing if routing intent is not used
  dynamic "routing" {
    for_each = local.vhub1_features.security.use_routing_intent ? [] : [1]
    content {
      associated_route_table_id = data.azurerm_virtual_hub_route_table.vhub1_default.id
      propagated_route_table {
        labels = [
          "default"
        ]
        route_table_ids = [
          data.azurerm_virtual_hub_route_table.vhub1_default.id
        ]
      }
      dynamic "static_vnet_route" {
        for_each = local.vhub1_spoke1_vnet_conn_routes
        content {
          name                = static_vnet_route.value.name
          address_prefixes    = static_vnet_route.value.address_prefixes
          next_hop_ip_address = static_vnet_route.value.next_hop_ip_address
        }
      }
    }
  }
}

# hub1

locals {
  vhub1_hub1_vnet_conn_routes = []
}

resource "azurerm_virtual_hub_connection" "hub1_vnet_conn" {
  name                      = "${local.vhub1_prefix}hub1-vnet-conn"
  virtual_hub_id            = module.vhub1.virtual_hub.id
  remote_virtual_network_id = module.hub1.vnet.id
  internet_security_enabled = false

  # only enable routing if routing intent is not used
  dynamic "routing" {
    for_each = local.vhub1_features.security.use_routing_intent ? [] : [1]
    content {
      associated_route_table_id = data.azurerm_virtual_hub_route_table.vhub1_default.id
      propagated_route_table {
        labels = [
          "default"
        ]
        route_table_ids = [
          data.azurerm_virtual_hub_route_table.vhub1_default.id
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
}

####################################################
# vhub static routes
####################################################

locals {
  vhub1_default_rt_static_routes = {
    #default = { destinations = ["0.0.0.0/0"], next_hop = module.vhub1.firewall.id }
    #rfc1918 = { destinations = local.private_prefixes, next_hop = module.vhub1.firewall.id }
    #zscaler = { destinations = ["${local.spoke2_vm_addr}/32"], next_hop = azurerm_virtual_hub_connection.hub1_vnet_conn.id }
  }
  vhub1_custom_rt_static_routes = {
    #default = { destinations = ["0.0.0.0/0"], next_hop = module.vhub1.firewall.id }
    #rfc1918 = { destinations = local.private_prefixes, next_hop = module.vhub1.firewall.id }
  }
}

resource "azurerm_virtual_hub_route_table_route" "vhub1_default_rt_static_routes" {
  for_each          = local.vhub1_features.security.enable_firewall ? local.vhub1_default_rt_static_routes : {}
  route_table_id    = data.azurerm_virtual_hub_route_table.vhub1_default.id
  name              = each.key
  destinations_type = "CIDR"
  destinations      = each.value.destinations
  next_hop_type     = "ResourceId"
  next_hop          = each.value.next_hop
  depends_on        = [module.hub1]
}

resource "azurerm_virtual_hub_route_table_route" "vhub1_custom_rt_static_routes" {
  for_each          = local.vhub1_features.security.enable_firewall ? local.vhub1_custom_rt_static_routes : {}
  route_table_id    = azurerm_virtual_hub_route_table.vhub1_custom[0].id
  name              = each.key
  destinations_type = "CIDR"
  destinations      = each.value.destinations
  next_hop_type     = "ResourceId"
  next_hop          = each.value.next_hop
  depends_on        = [module.hub1]
}

####################################################
# bgp connections
####################################################

# hub1

resource "azurerm_virtual_hub_bgp_connection" "vhub1_hub1_bgp_conn" {
  name           = "${local.vhub1_prefix}hub1-bgp-conn"
  virtual_hub_id = module.vhub1.virtual_hub.id
  peer_asn       = local.hub1_nva_asn
  peer_ip        = local.hub1_nva_addr

  virtual_network_connection_id = azurerm_virtual_hub_connection.hub1_vnet_conn.id
}

####################################################
# output files
####################################################

locals {
  hub1_files = {
    "output/hub1-linux-nva.sh" = local.hub1_linux_nva_init
  }
}

resource "local_file" "hub1_files" {
  for_each = local.hub1_files
  filename = each.key
  content  = each.value
}

