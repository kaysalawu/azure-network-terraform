
####################################################
# vnet connections
####################################################

locals {
  vhub2_hub1_vnet_conn_routes = []
}

# hub1

resource "azurerm_virtual_hub_connection" "hub1_vnet_conn" {
  name                      = "${local.vhub2_prefix}hub1-vnet-conn"
  virtual_hub_id            = module.vhub2.virtual_hub.id
  remote_virtual_network_id = module.hub1.vnet.id
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
        for_each = local.vhub2_hub1_vnet_conn_routes
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
  hub2_files = {
  }
}

resource "local_file" "hub2_files" {
  for_each = local.hub2_files
  filename = each.key
  content  = each.value
}

