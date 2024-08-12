
####################################################
# hub2
####################################################

# udr
#----------------------------

# main

module "hub2_udr_main" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.hub2_prefix}main"
  location       = local.hub2_location
  subnet_ids     = [module.hub2.subnets["MainSubnet"].id, ]
  routes = [for r in local.hub2_udr_main_routes : {
    name                   = r.name
    address_prefix         = r.address_prefix
    next_hop_type          = length(try(r.next_hop_ip, "")) > 0 ? "VirtualAppliance" : "Internet"
    next_hop_in_ip_address = length(try(r.next_hop_ip, "")) > 0 ? r.next_hop_ip : null
  }]

  bgp_route_propagation_enabled = false

  depends_on = [
    time_sleep.hub2,
  ]
}

####################################################
# vnet connections
####################################################

# hub2

locals {
  vhub2_hub2_vnet_conn_routes = []
}

resource "azurerm_virtual_hub_connection" "hub2_vnet_conn" {
  name                      = "${local.vhub2_prefix}hub2-vnet-conn"
  virtual_hub_id            = module.vhub2.virtual_hub.id
  remote_virtual_network_id = module.hub2.vnet.id
  internet_security_enabled = false

  routing {
    associated_route_table_id = data.azurerm_virtual_hub_route_table.vhub2_default.id
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

####################################################
# bgp connections
####################################################

# hub2

resource "azurerm_virtual_hub_bgp_connection" "vhub2_hub2_bgp_conn" {
  name           = "${local.vhub2_prefix}hub2-bgp-conn"
  virtual_hub_id = module.vhub2.virtual_hub.id
  peer_asn       = local.hub2_nva_asn
  peer_ip        = local.hub2_nva_untrust_addr

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

