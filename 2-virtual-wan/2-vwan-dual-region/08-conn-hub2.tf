
locals {
  vhub2_router_bgp_ip0   = module.vhub2.router_bgp_ip0
  vhub2_router_bgp_ip1   = module.vhub2.router_bgp_ip1
  vhub2_vpngw_public_ip0 = module.vhub2.vpn_gateway_public_ip0
  vhub2_vpngw_public_ip1 = module.vhub2.vpn_gateway_public_ip1
  vhub2_vpngw_bgp_ip0    = module.vhub2.vpn_gateway_bgp_ip0
  vhub2_vpngw_bgp_ip1    = module.vhub2.vpn_gateway_bgp_ip1
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
  use_remote_gateways          = false
}

# hub2-to-spoke5

resource "azurerm_virtual_network_peering" "hub2_to_spoke5_peering" {
  resource_group_name          = azurerm_resource_group.rg.name
  name                         = "${local.prefix}-hub2-to-spoke5-peering"
  virtual_network_name         = module.hub2.vnet.name
  remote_virtual_network_id    = module.spoke5.vnet.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
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
  next_hop_in_ip_address = local.hub2_nva_ilb_addr
  destinations = concat(
    ["0.0.0.0/0"],
    local.main_udr_destinations
  )
  depends_on = [module.hub2]
}

####################################################
# hub2
####################################################

# nva
#----------------------------

locals {
  hub2_router_route_map_name_nh = "NEXT-HOP"
  hub2_nva_vars = {
    LOCAL_ASN = local.hub2_nva_asn
    LOOPBACK0 = local.hub2_nva_loopback0
    LOOPBACKS = {
      Loopback1 = local.hub2_nva_ilb_addr
    }
    INT_ADDR = local.hub2_nva_addr
    VPN_PSK  = local.psk
  }
  hub2_linux_nva_init = templatefile("../../scripts/linux-nva.sh", merge(local.hub2_nva_vars, {
    TARGETS        = local.vm_script_targets_region2
    IPTABLES_RULES = []
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
    QUAGGA_ZEBRA_CONF = templatefile("../../scripts/quagga/zebra.conf", merge(
      local.hub2_nva_vars,
      {
        INTERFACE = "eth0"
        STATIC_ROUTES = [
          { prefix = "0.0.0.0/0", next_hop = local.hub2_default_gw_nva },
          { prefix = "${local.vhub2_router_bgp_ip0}/32", next_hop = local.hub2_default_gw_nva },
          { prefix = "${local.vhub2_router_bgp_ip1}/32", next_hop = local.hub2_default_gw_nva },
          { prefix = local.spoke5_address_space[0], next_hop = local.hub2_default_gw_nva },
        ]
      }
    ))
    QUAGGA_BGPD_CONF = templatefile("../../scripts/quagga/bgpd.conf", merge(
      local.hub2_nva_vars,
      {
        BGP_SESSIONS = [
          {
            peer_asn      = local.vhub2_bgp_asn
            peer_ip       = local.vhub2_router_bgp_ip0
            ebgp_multihop = true
            route_map = {
              #name      = local.hub2_router_route_map_name_nh
              #direction = "out"
            }
          },
          {
            peer_asn      = local.vhub2_bgp_asn
            peer_ip       = local.vhub2_router_bgp_ip1
            ebgp_multihop = true
            route_map = {
              #name      = local.hub2_router_route_map_name_nh
              #direction = "out"
            }
          },
        ]
        BGP_ADVERTISED_PREFIXES = [
          local.hub2_subnets["${local.hub2_prefix}main"].address_prefixes[0],
          local.spoke5_address_space[0],
          #"${local.spoke6_vm_public_ip}/32"
        ]
      }
    ))
    }
  ))
}

module "hub2_nva" {
  source               = "../../modules/linux"
  resource_group       = azurerm_resource_group.rg.name
  prefix               = ""
  name                 = "${local.hub2_prefix}nva"
  location             = local.hub2_location
  subnet               = module.hub2.subnets["${local.hub2_prefix}nva"].id
  private_ip           = local.hub2_nva_addr
  enable_ip_forwarding = true
  enable_public_ip     = true
  source_image         = "ubuntu"
  storage_account      = module.common.storage_accounts["region2"]
  admin_username       = local.username
  admin_password       = local.password
  custom_data          = base64encode(local.hub2_linux_nva_init)
}

# udr

module "hub2_udr_main" {
  source                 = "../../modules/udr"
  resource_group         = azurerm_resource_group.rg.name
  prefix                 = "${local.hub2_prefix}main"
  location               = local.hub2_location
  subnet_id              = module.hub2.subnets["${local.hub2_prefix}main"].id
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.hub2_nva_ilb_addr
  destinations           = local.main_udr_destinations
  depends_on             = [module.hub2]
}
/*
module "hub2_udr_nva" {
  source         = "../../modules/udr"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.hub2_prefix}nva"
  location       = local.hub2_location
  subnet_id      = module.hub2.subnets["${local.hub2_prefix}nva"].id
  next_hop_type  = "Internet"
  destinations   = ["${local.spoke6_vm_public_ip}/32", ]
  depends_on     = [module.hub2]
}*/

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

# sites
#----------------------------

# branch3

resource "azurerm_vpn_site" "vhub2_site_branch3" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.vhub2_prefix}site-branch3"
  location            = azurerm_virtual_wan.vwan.location
  virtual_wan_id      = azurerm_virtual_wan.vwan.id
  device_model        = "Azure"
  device_vendor       = "Microsoft"
  link {
    name          = "${local.vhub2_prefix}site-branch3-link-0"
    provider_name = "Microsoft"
    ip_address    = azurerm_public_ip.branch3_nva_pip.ip_address
    speed_in_mbps = 50
    bgp {
      asn             = local.branch3_nva_asn
      peering_address = local.branch3_nva_loopback0
    }
  }
}

resource "azurerm_vpn_gateway_connection" "vhub2_site_branch3_conn" {
  name                      = "${local.vhub2_prefix}site-branch3-conn"
  vpn_gateway_id            = module.vhub2.vpn_gateway.id
  remote_vpn_site_id        = azurerm_vpn_site.vhub2_site_branch3.id
  internet_security_enabled = true

  vpn_link {
    name             = "${local.vhub2_prefix}site-branch3-conn-vpn-link-0"
    bgp_enabled      = true
    shared_key       = local.psk
    vpn_site_link_id = azurerm_vpn_site.vhub2_site_branch3.link[0].id
  }

  # only enable routing if routing intent is not used
  dynamic "routing" {
    for_each = local.vhub2_features.security.use_routing_intent ? [] : [1]
    content {
      associated_route_table = module.vhub2.virtual_hub.default_route_table_id
      propagated_route_table {
        labels = [
          "default",
        ]
        route_table_ids = [
          module.vhub2.virtual_hub.default_route_table_id,
        ]
      }
    }
  }
}

####################################################
# vnet connections
####################################################

locals {
  vhub2_spoke4_vnet_conn_routes = []
}

# spoke4

resource "azurerm_virtual_hub_connection" "spoke4_vnet_conn" {
  name                      = "${local.vhub2_prefix}spoke4-vnet-conn"
  virtual_hub_id            = module.vhub2.virtual_hub.id
  remote_virtual_network_id = module.spoke4.vnet.id
  internet_security_enabled = true

  # only enable routing if routing intent is not used
  dynamic "routing" {
    for_each = local.vhub2_features.security.use_routing_intent ? [] : [1]
    content {
      associated_route_table_id = data.azurerm_virtual_hub_route_table.vhub2_default.id
      propagated_route_table {
        labels = [
          "default"
        ]
        route_table_ids = [
          data.azurerm_virtual_hub_route_table.vhub2_default.id
        ]
      }
      dynamic "static_vnet_route" {
        for_each = local.vhub2_spoke4_vnet_conn_routes
        content {
          name                = static_vnet_route.value.name
          address_prefixes    = static_vnet_route.value.address_prefixes
          next_hop_ip_address = static_vnet_route.value.next_hop_ip_address
        }
      }
    }
  }
}

# hub2

locals {
  vhub2_hub2_vnet_conn_routes = []
}

resource "azurerm_virtual_hub_connection" "hub2_vnet_conn" {
  name                      = "${local.vhub2_prefix}hub2-vnet-conn"
  virtual_hub_id            = module.vhub2.virtual_hub.id
  remote_virtual_network_id = module.hub2.vnet.id
  internet_security_enabled = false

  # only enable routing if routing intent is not used
  dynamic "routing" {
    for_each = local.vhub2_features.security.use_routing_intent ? [] : [1]
    content {
      associated_route_table_id = data.azurerm_virtual_hub_route_table.vhub2_default.id
      propagated_route_table {
        labels = [
          "default"
        ]
        route_table_ids = [
          data.azurerm_virtual_hub_route_table.vhub2_default.id
        ]
      }
      dynamic "static_vnet_route" {
        for_each = local.vhub2_hub2_vnet_conn_routes
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
  vhub2_default_rt_static_routes = {
    #default = { destinations = ["0.0.0.0/0"], next_hop = module.vhub2.firewall.id }
    #rfc1918 = { destinations = local.private_prefixes, next_hop = module.vhub2.firewall.id }
    #zscaler = { destinations = ["${local.spoke5_vm_addr}/32"], next_hop = azurerm_virtual_hub_connection.hub2_vnet_conn.id }
  }
  vhub2_custom_rt_static_routes = {
    #default = { destinations = ["0.0.0.0/0"], next_hop = module.vhub2.firewall.id }
    #rfc1918 = { destinations = local.private_prefixes, next_hop = module.vhub2.firewall.id }
  }
}

resource "azurerm_virtual_hub_route_table_route" "vhub2_default_rt_static_routes" {
  for_each          = local.vhub2_features.security.enable_firewall ? local.vhub2_default_rt_static_routes : {}
  route_table_id    = data.azurerm_virtual_hub_route_table.vhub2_default.id
  name              = each.key
  destinations_type = "CIDR"
  destinations      = each.value.destinations
  next_hop_type     = "ResourceId"
  next_hop          = each.value.next_hop
  depends_on        = [module.hub2]
}

resource "azurerm_virtual_hub_route_table_route" "vhub2_custom_rt_static_routes" {
  for_each          = local.vhub2_features.security.enable_firewall ? local.vhub2_custom_rt_static_routes : {}
  route_table_id    = azurerm_virtual_hub_route_table.vhub2_custom[0].id
  name              = each.key
  destinations_type = "CIDR"
  destinations      = each.value.destinations
  next_hop_type     = "ResourceId"
  next_hop          = each.value.next_hop
  depends_on        = [module.hub2]
}

####################################################
# bgp connections
####################################################

# hub2

resource "azurerm_virtual_hub_bgp_connection" "vhub2_hub2_bgp_conn" {
  name           = "${local.vhub2_prefix}hub2-bgp-conn"
  virtual_hub_id = module.vhub2.virtual_hub.id
  peer_asn       = local.hub2_nva_asn
  peer_ip        = local.hub2_nva_addr

  virtual_network_connection_id = azurerm_virtual_hub_connection.hub2_vnet_conn.id
}

####################################################
# output files
####################################################

locals {
  hub2_files = {
    "output/hub2-linux-nva.sh" = local.hub2_linux_nva_init
  }
}

resource "local_file" "hub2_files" {
  for_each = local.hub2_files
  filename = each.key
  content  = each.value
}

