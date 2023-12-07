
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
  depends_on                   = [azurerm_virtual_network_peering.spoke5_to_hub2_peering]
}

# udr
#----------------------------

# main

module "spoke5_udr_main" {
  source                        = "../../modules/udr"
  resource_group                = azurerm_resource_group.rg.name
  prefix                        = "${local.spoke5_prefix}main"
  location                      = local.spoke5_location
  subnet_id                     = module.spoke5.subnets["MainSubnet"].id
  next_hop_type                 = "VirtualAppliance"
  next_hop_in_ip_address        = local.hub2_nva_ilb_addr
  disable_bgp_route_propagation = true

  destinations = merge(
    local.default_udr_destinations,
    { "hub2" = local.hub2_address_space[0] }
  )
  depends_on = [
    module.hub2,
    module.vhub2,
  ]
}

####################################################
# hub2
####################################################

# udr
#----------------------------

# main

module "hub2_udr_main" {
  source                        = "../../modules/udr"
  resource_group                = azurerm_resource_group.rg.name
  prefix                        = "${local.hub2_prefix}main"
  location                      = local.hub2_location
  subnet_id                     = module.hub2.subnets["MainSubnet"].id
  next_hop_type                 = "VirtualAppliance"
  next_hop_in_ip_address        = local.hub2_nva_ilb_addr
  disable_bgp_route_propagation = true

  destinations = merge(
    local.default_udr_destinations,
    {
      "spoke4" = local.spoke4_address_space[0]
      "spoke5" = local.spoke5_address_space[0]
    }
  )
  depends_on = [
    module.hub2,
    module.vhub2,
  ]
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
  vpn_gateway_id            = module.vhub2.vpngw.id
  remote_vpn_site_id        = azurerm_vpn_site.vhub2_site_branch3.id
  internet_security_enabled = true

  vpn_link {
    name             = "${local.vhub2_prefix}site-branch3-conn-vpn-link-0"
    bgp_enabled      = true
    shared_key       = local.psk
    vpn_site_link_id = azurerm_vpn_site.vhub2_site_branch3.link[0].id
  }

  # disable routing when routing intent is used
  dynamic "routing" {
    for_each = local.vhub2_features.config_security.enable_routing_intent ? [] : [1]
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

  # disable routing when routing intent is used
  dynamic "routing" {
    for_each = local.vhub2_features.config_security.enable_routing_intent ? [] : [1]
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

  # disable routing when routing intent is used
  dynamic "routing" {
    for_each = local.vhub2_features.config_security.enable_routing_intent ? [] : [1]
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
  for_each          = local.vhub2_features.config_security.create_firewall ? local.vhub2_default_rt_static_routes : {}
  route_table_id    = data.azurerm_virtual_hub_route_table.vhub2_default.id
  name              = each.key
  destinations_type = "CIDR"
  destinations      = each.value.destinations
  next_hop_type     = "ResourceId"
  next_hop          = each.value.next_hop
  depends_on        = [module.hub2]
}

# resource "azurerm_virtual_hub_route_table_route" "vhub2_custom_rt_static_routes" {
#   for_each          = local.vhub2_features.config_security.create_firewall ? local.vhub2_custom_rt_static_routes : {}
#   route_table_id    = azurerm_virtual_hub_route_table.vhub2_custom[0].id
#   name              = each.key
#   destinations_type = "CIDR"
#   destinations      = each.value.destinations
#   next_hop_type     = "ResourceId"
#   next_hop          = each.value.next_hop
#   depends_on        = [module.hub2]
# }

####################################################
# bgp connections
####################################################

# hub2

resource "azurerm_virtual_hub_bgp_connection" "vhub2_hub2_bgp_conn" {
  name           = "${local.vhub2_prefix}hub2-bgp-conn"
  virtual_hub_id = module.vhub2.virtual_hub.id
  peer_asn       = local.hub2_nva_asn
  peer_ip        = local.hub2_nva_trust_addr

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

