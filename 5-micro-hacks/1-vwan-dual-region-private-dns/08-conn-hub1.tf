
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

  dynamic "routing" {
    for_each = try(local.vhub1_features.config_security.enable_routing_intent, false) ? [] : [1]
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
  vhub1_spoke2_vnet_conn_routes = []
}

# spoke1

resource "azurerm_virtual_hub_connection" "spoke1_vnet_conn" {
  name                      = "${local.vhub1_prefix}spoke1-vnet-conn"
  virtual_hub_id            = module.vhub1.virtual_hub.id
  remote_virtual_network_id = module.spoke1.vnet.id
  internet_security_enabled = true

  # disable routing when routing intent is used
  dynamic "routing" {
    for_each = try(local.vhub1_features.config_security.enable_routing_intent, false) ? [] : [1]
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

# spoke2

resource "azurerm_virtual_hub_connection" "spoke2_vnet_conn" {
  name                      = "${local.vhub1_prefix}spoke2-vnet-conn"
  virtual_hub_id            = module.vhub1.virtual_hub.id
  remote_virtual_network_id = module.spoke2.vnet.id
  internet_security_enabled = true

  # disable routing when routing intent is used
  dynamic "routing" {
    for_each = try(local.vhub1_features.config_security.enable_routing_intent, false) ? [] : [1]
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
        for_each = local.vhub1_spoke2_vnet_conn_routes
        content {
          name                = static_vnet_route.value.name
          address_prefixes    = static_vnet_route.value.address_prefixes
          next_hop_ip_address = static_vnet_route.value.next_hop_ip_address
        }
      }
    }
  }
}

# shared1

locals {
  vhub1_shared1_vnet_conn_routes = []
}

resource "azurerm_virtual_hub_connection" "shared1_vnet_conn" {
  name                      = "${local.vhub1_prefix}shared1-vnet-conn"
  virtual_hub_id            = module.vhub1.virtual_hub.id
  remote_virtual_network_id = module.shared1.vnet.id
  internet_security_enabled = false

  # disable routing when routing intent is used
  dynamic "routing" {
    for_each = try(local.vhub1_features.config_security.enable_routing_intent, false) ? [] : [1]
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
        for_each = local.vhub1_shared1_vnet_conn_routes
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
    #zscaler = { destinations = ["${local.spoke2_vm_addr}/32"], next_hop = azurerm_virtual_hub_connection.shared1_vnet_conn.id }
  }
  vhub1_custom_rt_static_routes = {
    #default = { destinations = ["0.0.0.0/0"], next_hop = module.vhub1.firewall.id }
    #rfc1918 = { destinations = local.private_prefixes, next_hop = module.vhub1.firewall.id }
  }
}

resource "azurerm_virtual_hub_route_table_route" "vhub1_default_rt_static_routes" {
  for_each          = try(local.vhub1_features.config_security.create_firewall, false) ? local.vhub1_default_rt_static_routes : {}
  route_table_id    = data.azurerm_virtual_hub_route_table.vhub1_default.id
  name              = each.key
  destinations_type = "CIDR"
  destinations      = each.value.destinations
  next_hop_type     = "ResourceId"
  next_hop          = each.value.next_hop
  depends_on        = [module.shared1]
}

####################################################
# output files
####################################################

locals {
  shared1_files = {
    #"output/shared1-linux-nva.sh" = local.shared1_linux_nva_init
  }
}

resource "local_file" "shared1_files" {
  for_each = local.shared1_files
  filename = each.key
  content  = each.value
}

