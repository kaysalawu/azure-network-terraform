
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
  depends_on = [
    module.spoke2,
    module.hub1,
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
  allow_gateway_transit        = false
  depends_on = [
    module.spoke2,
    module.hub1,
  ]
}

# udr
#----------------------------

# main

locals {
  spoke2_routes_main = concat(local.default_udr_destinations, [
    { name = "hub1", address_prefix = local.hub1_address_space },
  ])
}

module "spoke2_udr_main" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.spoke2_prefix}main"
  location       = local.spoke2_location
  subnet_id      = module.spoke2.subnets["MainSubnet"].id
  routes = [for r in local.spoke2_routes_main : {
    name                   = r.name
    address_prefix         = r.address_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = local.hub1_nva_ilb_trust_addr
  }]

  disable_bgp_route_propagation = true

  depends_on = [
    module.hub1,
    module.vhub1,
  ]
}

####################################################
# hub1
####################################################

# udr
#----------------------------

# main

locals {
  hub1_udr_main_routes = concat(local.default_udr_destinations, [
    { name = "spoke1", address_prefix = local.spoke1_address_space },
    { name = "spoke2", address_prefix = local.spoke2_address_space },
  ])
}

module "hub1_udr_main" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.hub1_prefix}main"
  location       = local.hub1_location
  subnet_id      = module.hub1.subnets["MainSubnet"].id
  routes = [for r in local.hub1_udr_main_routes : {
    name                   = r.name
    address_prefix         = r.address_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = local.hub1_nva_ilb_trust_addr
  }]

  disable_bgp_route_propagation = true

  depends_on = [
    module.hub1,
    module.vhub1,
  ]
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
  vpn_gateway_id            = module.vhub1.vpngw.id
  remote_vpn_site_id        = azurerm_vpn_site.vhub1_site_branch1.id
  internet_security_enabled = true

  vpn_link {
    name             = "${local.vhub1_prefix}site-branch1-conn-vpn-link-0"
    bgp_enabled      = true
    shared_key       = local.psk
    vpn_site_link_id = azurerm_vpn_site.vhub1_site_branch1.link[0].id
  }

  # disable routing when routing intent is used
  dynamic "routing" {
    for_each = local.vhub1_features.config_security.enable_routing_intent ? [] : [1]
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

  # disable routing when routing intent is used
  dynamic "routing" {
    for_each = local.vhub1_features.config_security.enable_routing_intent ? [] : [1]
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

  # disable routing when routing intent is used
  dynamic "routing" {
    for_each = local.vhub1_features.config_security.enable_routing_intent ? [] : [1]
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
  for_each          = local.vhub1_features.config_security.create_firewall ? local.vhub1_default_rt_static_routes : {}
  route_table_id    = data.azurerm_virtual_hub_route_table.vhub1_default.id
  name              = each.key
  destinations_type = "CIDR"
  destinations      = each.value.destinations
  next_hop_type     = "ResourceId"
  next_hop          = each.value.next_hop
  depends_on        = [module.hub1]
}

# resource "azurerm_virtual_hub_route_table_route" "vhub1_custom_rt_static_routes" {
#   for_each          = local.vhub1_features.config_security.create_firewall ? local.vhub1_custom_rt_static_routes : {}
#   route_table_id    = azurerm_virtual_hub_route_table.vhub1_custom[0].id
#   name              = each.key
#   destinations_type = "CIDR"
#   destinations      = each.value.destinations
#   next_hop_type     = "ResourceId"
#   next_hop          = each.value.next_hop
#   depends_on        = [module.hub1]
# }

####################################################
# bgp connections
####################################################

# hub1

resource "azurerm_virtual_hub_bgp_connection" "vhub1_hub1_bgp_conn" {
  name           = "${local.vhub1_prefix}hub1-bgp-conn"
  virtual_hub_id = module.vhub1.virtual_hub.id
  peer_asn       = local.hub1_nva_asn
  peer_ip        = local.hub1_nva_untrust_addr

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

