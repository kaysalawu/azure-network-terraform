
####################################################
# spoke4
####################################################

# udr
#----------------------------

# main

module "spoke4_udr_main" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.spoke4_prefix}main"
  location       = local.spoke4_location
  subnet_id      = module.spoke4.subnets["MainSubnet"].id
  routes = [for r in local.spoke4_udr_main_routes : {
    name                   = r.name
    address_prefix         = r.address_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = r.next_hop_ip
  }]

  disable_bgp_route_propagation = true

  depends_on = [
    time_sleep.hub2,
  ]
}

####################################################
# spoke5
####################################################

# udr
#----------------------------

# main

module "spoke5_udr_main" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.spoke5_prefix}main"
  location       = local.spoke5_location
  subnet_id      = module.spoke5.subnets["MainSubnet"].id
  routes = [for r in local.spoke5_udr_main_routes : {
    name                   = r.name
    address_prefix         = r.address_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = r.next_hop_ip
  }]

  disable_bgp_route_propagation = true

  depends_on = [
    time_sleep.hub2,
  ]
}

####################################################
# hub2
####################################################

# udr
#----------------------------

# gateway

module "hub2_gateway_udr" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.hub2_prefix}gateway"
  location       = local.hub2_location
  subnet_id      = module.hub2.subnets["GatewaySubnet"].id
  routes = [for r in local.hub2_gateway_udr_destinations : {
    name                   = r.name
    address_prefix         = r.address_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = r.next_hop_ip
  }]

  depends_on = [
    time_sleep.hub2,
  ]
}

# main

module "hub2_udr_main" {
  source         = "../../modules/route-table"
  resource_group = azurerm_resource_group.rg.name
  prefix         = "${local.hub2_prefix}main"
  location       = local.hub2_location
  subnet_id      = module.hub2.subnets["MainSubnet"].id
  routes = [for r in local.hub2_udr_main_routes : {
    name                   = r.name
    address_prefix         = r.address_prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = r.next_hop_ip
  }]

  disable_bgp_route_propagation = true

  depends_on = [
    time_sleep.hub2,
  ]
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
  gateway_address     = azurerm_public_ip.branch3_nva_pip[0].ip_address
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
  resource_group_name            = azurerm_resource_group.rg.name
  name                           = "${local.hub2_prefix}branch3-lng-conn"
  location                       = local.hub2_location
  type                           = "IPsec"
  enable_bgp                     = true
  virtual_network_gateway_id     = module.hub2.s2s_vpngw.id
  local_network_gateway_id       = azurerm_local_network_gateway.hub2_branch3_lng.id
  local_azure_ip_address_enabled = false
  shared_key                     = local.psk
  egress_nat_rule_ids            = []
  ingress_nat_rule_ids           = []
}

####################################################
# output files
####################################################

locals {
  hub2_files = {}
}

resource "local_file" "hub2_files" {
  for_each = local.hub2_files
  filename = each.key
  content  = each.value
}

