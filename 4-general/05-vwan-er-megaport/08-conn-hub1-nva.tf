
####################################################
# vpn-site connection
####################################################

# sites
#----------------------------

# branch2

resource "azurerm_vpn_site" "vhub1_site_branch2" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${local.vhub1_prefix}site-branch2"
  location            = azurerm_virtual_wan.vwan.location
  virtual_wan_id      = azurerm_virtual_wan.vwan.id
  device_model        = "Azure"
  device_vendor       = "Microsoft"
  link {
    name          = "${local.vhub1_prefix}site-branch2-link-0"
    provider_name = "Microsoft"
    ip_address    = azurerm_public_ip.branch2_nva_pip.ip_address
    speed_in_mbps = 50
    bgp {
      asn             = local.branch2_nva_asn
      peering_address = local.branch2_nva_loopback0
    }
  }
}

resource "azurerm_vpn_gateway_connection" "vhub1_site_branch2_conn" {
  name                      = "${local.vhub1_prefix}site-branch2-conn"
  vpn_gateway_id            = module.vhub1.vpngw.id
  remote_vpn_site_id        = azurerm_vpn_site.vhub1_site_branch2.id
  internet_security_enabled = true

  vpn_link {
    name             = "${local.vhub1_prefix}site-branch2-conn-vpn-link-0"
    bgp_enabled      = true
    shared_key       = local.psk
    vpn_site_link_id = azurerm_vpn_site.vhub1_site_branch2.link[0].id
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

####################################################
# output files
####################################################

locals {
  hub1_files = {
  }
}

resource "local_file" "hub1_files" {
  for_each = local.hub1_files
  filename = each.key
  content  = each.value
}

